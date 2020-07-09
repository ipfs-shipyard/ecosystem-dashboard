class Package < ApplicationRecord
  include Releases

  include PgSearch::Model
  pg_search_scope :search_by_name,
                  against: :name,
                  order_within_rank: 'packages.collab_dependent_repos_count DESC nulls last',
                  using: {
                    tsearch: {
                      prefix: true,
                      negation: true,
                      dictionary: "english"
                    }
                  }

  validates_presence_of :name, :platform
  validates_uniqueness_of :name, scope: :platform, case_sensitive: true

  belongs_to :repository, optional: true
  has_one :organization, through: :repository
  has_many :versions
  has_many :dependencies, -> { group 'package_name' }, through: :versions

  has_many :tags, through: :repository
  has_many :published_tags, -> { where('published_at IS NOT NULL') }, through: :repository, class_name: 'Tag'
  has_many :dependents, class_name: 'Dependency'
  has_many :dependent_versions, through: :dependents, source: :version, class_name: 'Version'
  has_many :dependent_packages, -> { group('packages.id') }, through: :dependent_versions, source: :packages, class_name: 'Package'
  has_many :repository_dependencies
  has_many :dependent_repositories, -> { group('repositories.id').order('repositories.stargazers_count DESC') }, through: :repository_dependencies, source: :repository
  has_many :direct_dependent_repositories, -> { where(repository_dependencies: {direct: true}).group('repositories.id').order('repositories.stargazers_count DESC') }, through: :repository_dependencies, source: :repository

  scope :platform, ->(platform) { where(platform: PackageManager::Base.format_name(platform)) }
  scope :lower_platform, ->(platform) { where('lower(packages.platform) = ?', platform.try(:downcase)) }
  scope :lower_name, ->(name) { where('lower(packages.name) = ?', name.try(:downcase)) }

  scope :exclude_platform, ->(platforms) { where.not(platform: platforms.map{|p|PackageManager::Base.format_name(p)}) }

  scope :with_homepage, -> { where("homepage <> ''") }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :without_repository_url, -> { where("repository_url IS ? OR repository_url = ''", nil) }
  scope :with_repo, -> { joins(:repository).where('repositories.id IS NOT NULL') }
  scope :without_repo, -> { where(repository_id: nil) }
  scope :with_description, -> { where("packages.description <> ''") }

  scope :with_license, -> { where("licenses <> ''") }
  scope :without_license, -> { where("licenses IS ? OR licenses = ''", nil) }
  scope :unlicensed, -> { maintained.without_license.with_repo.where("repositories.license IS ? OR repositories.license = ''", nil) }

  scope :with_versions, -> { where('versions_count > 0') }
  scope :without_versions, -> { where('versions_count < 1') }
  scope :few_versions, -> { where('versions_count < 2') }
  scope :many_versions, -> { where('versions_count > 2') }

  scope :with_dependents, -> { where('dependents_count > 0') }
  scope :with_dependent_repos, -> { where('dependent_repos_count > 0') }

  scope :with_github_url, -> { where('repository_url ILIKE ?', '%github.com%') }
  scope :with_gitlab_url, -> { where('repository_url ILIKE ?', '%gitlab.com%') }
  scope :with_bitbucket_url, -> { where('repository_url ILIKE ?', '%bitbucket.org%') }
  scope :with_launchpad_url, -> { where('repository_url ILIKE ?', '%launchpad.net%') }
  scope :with_sourceforge_url, -> { where('repository_url ILIKE ?', '%sourceforge.net%') }

  scope :most_watched, -> { joins(:subscriptions).group('packages.id').order(Arel.sql("COUNT(subscriptions.id) DESC")) }
  scope :most_dependents, -> { with_dependents.order(Arel.sql('dependents_count DESC')) }
  scope :most_dependent_repos, -> { with_dependent_repos.order(Arel.sql('dependent_repos_count DESC')) }

  scope :visible, -> { where('packages."status" != ? OR packages."status" IS NULL', "Hidden")}
  scope :maintained, -> { where('packages."status" not in (?) OR packages."status" IS NULL', ["Deprecated", "Removed", "Unmaintained", "Hidden"])}
  scope :deprecated, -> { where('packages."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('packages."status" not in (?) OR packages."status" IS NULL', ["Removed", "Hidden"])}
  scope :removed, -> { where('packages."status" = ?', "Removed")}
  scope :unmaintained, -> { where('packages."status" = ?', "Unmaintained")}
  scope :hidden, -> { where('packages."status" = ?', "Hidden")}

  scope :indexable, -> { not_removed.includes(:repository) }

  scope :unsung_heroes, -> { maintained
                             .with_repo
                             .where('repositories.stargazers_count < 100')
                             .where('packages.dependent_repos_count > 1000') }

  scope :digital_infrastructure, -> { not_removed
                             .with_repo
                             .where('packages.dependent_repos_count > ?', 10000)}

  scope :hacker_news, -> { with_repo.where('repositories.stargazers_count > 0').order(Arel.sql("((repositories.stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-repositories.created_at)/3600)+2,1.8)) DESC")) }
  scope :recently_created, -> { with_repo.where('repositories.created_at > ?', 2.weeks.ago)}

  scope :internal, -> { joins(:organization).where('organizations.internal = ?', true) }
  scope :external, -> { where.not(repository_id: Repository.internal.pluck(:id)) }

  scope :exclude_org, ->(org) { joins(:organization).where('organizations.name != ?', org) }
  scope :org, ->(org) { joins(:organization).where('organizations.name = ?', org) }

  scope :this_period, ->(period) { where('packages.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('packages.created_at > ?', (period*2).days.ago).where('packages.created_at < ?', period.days.ago) }

  after_commit :update_repository, on: :create
  after_commit :set_dependents_count, on: [:create, :update]
  before_save  :update_details
  before_destroy :destroy_versions

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  def forced_save
    self.updated_at = Time.zone.now
    save
  end

  def sync
    check_status
    if status == 'Removed'
      set_last_synced_at
      return
    end

    result = platform_class.update(name)
    set_last_synced_at unless result
  rescue
    set_last_synced_at
  end

  def set_last_synced_at
    update_column(:last_synced_at, Time.zone.now)
  end

  def async_sync
    # PackageManagerDownloadWorker.perform_async(platform, name)
  end

  def recently_synced?
    last_synced_at && last_synced_at > 1.day.ago
  end

  def update_details
    normalize_licenses
    set_latest_release_published_at
    set_latest_release_number
    set_latest_stable_release_info
    set_runtime_dependencies_count
    set_language
  end

  def keywords
    (Array(keywords_array) + Array(repository.try(:keywords) || [])).compact.uniq(&:downcase)
  end

  def package_manager_url(version = nil)
    platform_class.package_link(self, version)
  end

  def download_url(version = nil)
    platform_class.download_url(name, version) if version
  end

  def latest_download_url
    download_url(latest_release_number)
  end

  def documentation_url(version = nil)
    platform_class.documentation_url(name, version)
  end

  def install_instructions(version = nil)
    platform_class.install_instructions(self, version)
  end

  def platform_class
    "PackageManager::#{platform}".constantize
  end

  def platform_name
    platform_class.formatted_name
  end

  def color
    Languages::Language[language].try(:color) || platform_class.try(:color)
  end

  def destroy_versions
    versions.find_each(&:destroy)
  end

  def stars
    repository.try(:stargazers_count) || 0
  end

  def forks
    repository.try(:forks_count) || 0
  end

  def watchers
    repository.try(:subscribers_count) || 0
  end

  def set_language
    return unless repository
    self.language = repository.try(:language)
  end

  def repo_name
    repository.try(:full_name)
  end

  def description
    if platform == 'Go'
      repository.try(:description).presence || read_attribute(:description)
    else
      read_attribute(:description).presence || repository.try(:description)
    end
  end

  def homepage
    read_attribute(:homepage).presence || repository.try(:homepage)
  end

  def set_dependents_count
    return if destroyed?
    new_dependents_count = dependents.joins(:version).pluck(Arel.sql('DISTINCT versions.package_id')).count
    new_dependent_repos_count = dependent_repositories.active.source.count.length
    new_collab_dependent_repos_count = direct_dependent_repositories.active.source.external.count.length

    updates = {}
    updates[:dependents_count] = new_dependents_count if read_attribute(:dependents_count) != new_dependents_count
    updates[:dependent_repos_count] = new_dependent_repos_count if read_attribute(:dependent_repos_count) != new_dependent_repos_count
    updates[:collab_dependent_repos_count] = new_collab_dependent_repos_count if read_attribute(:collab_dependent_repos_count) != new_collab_dependent_repos_count
    self.update_columns(updates) if updates.present?
  end

  def needs_suggestions?
    repository_url.blank? || normalized_licenses.blank?
  end

  def self.undownloaded_repos
    with_github_url.or(with_gitlab_url).or(with_bitbucket_url).without_repo
  end

  def self.license(license)
    where("packages.normalized_licenses @> ?", Array(license).to_postgres_array(true))
  end

  def self.keyword(keyword)
    where("packages.keywords_array @> ?", Array(keyword).to_postgres_array(true))
  end

  def self.keywords(keywords)
    where("packages.keywords_array && ?", Array(keywords).to_postgres_array(true))
  end

  def self.language(language)
    where('lower(packages.language) = ?', language.try(:downcase))
  end

  def self.all_languages
    @all_languages ||= Languages::Language.all.map{|l| l.name.downcase}
  end

  def self.popular_languages(options = {})
    facets(options)[:languages].language.buckets
  end

  def self.popular_platforms(options = {})
    facets(options)[:platforms].platform.buckets.reject{ |t| ['biicode', 'jam'].include?(t['key'].downcase) }
  end

  def self.keywords_badlist
    ['bsd3', 'library']
  end

  def self.popular_keywords(options = {})
    facets(options)[:keywords].keywords_array.buckets.reject{ |t| all_languages.include?(t['key'].downcase) }.reject{|t| keywords_badlist.include?(t['key'].downcase) }
  end

  def self.popular_licenses(options = {})
    facets(options)[:licenses].normalized_licenses.buckets.reject{ |t| t['key'].downcase == 'other' }
  end

  def normalized_licenses
    read_attribute(:normalized_licenses).presence || [Package.format_license(repository.try(:license))].compact
  end

  def self.format_license(license)
    return nil if license.blank?
    return 'Other' if license.downcase == 'other'
    Spdx.find(license).try(:id) || license
  end

  def self.find_best(*args)
    find_best!(*args)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.find_best!(platform, name, includes=[])
    find_with_package_manager!(platform, name, includes)
  end

  private_class_method def self.find_with_package_manager!(platform, name, includes=[])
    platform_class = PackageManager::Base.find(platform)
    raise ActiveRecord::RecordNotFound if platform_class.nil?
    names = platform_class
      .package_find_names(name)
      .map(&:downcase)

    platform(platform)
      .where("lower(packages.name) in (?)", names)
      .includes(includes.present? ? includes : nil)
      .first!
  end

  def normalize_licenses
    self.normalized_licenses =
      if licenses.blank?
        []

      elsif licenses.length > 150
        self.license_normalized = true
        ["Other"]

      else
        spdx = spdx_license

        if spdx.empty?
          self.license_normalized = true
          ["Other"]

        else
          self.license_normalized = spdx.first != licenses
          spdx

        end
      end
  end

  def update_repository_async
    #RepositoryPackageWorker.perform_async(self.id) if known_repository_host_name.present?
  end

  def known_repository_host_name
    github_name_with_owner || bitbucket_name_with_owner || gitlab_name_with_owner
  end

  def known_repository_host
    return 'GitHub' if github_name_with_owner.present?
    return 'Bitbucket' if bitbucket_name_with_owner
    return 'GitLab' if gitlab_name_with_owner
  end

  def can_have_dependencies?
    return false if platform_class == Package
    platform_class::HAS_DEPENDENCIES
  end

  def can_have_entire_package_deprecated?
    return false if platform_class == Package
    platform_class::ENTIRE_PACKAGE_CAN_BE_DEPRECATED
  end

  def can_have_versions?
    return false if platform_class == Package
    platform_class::HAS_VERSIONS
  end

  def release_or_tag
    can_have_versions? ? 'releases' : 'tags'
  end

  def update_repository
    return false unless known_repository_host_name.present?
    r = Repository.find_by_full_name(known_repository_host_name)
    return if r.nil?
    unless self.new_record?
      self.repository_id = r.id
      self.forced_save
    end
  end

  def subscribed_repos(user)
    subscriptions.with_repository_subscription.where('repository_subscriptions.user_id = ?', user.id).map(&:repository).uniq
  end

  def check_status(removed = false)
    url = platform_class.check_status_url(self)
    return if url.blank?
    response = Typhoeus.head(url)
    if platform.downcase == 'packagist' && response.response_code == 302
      update_column(:status, 'Removed')
    elsif platform.downcase != 'packagist' && [400, 404].include?(response.response_code)
      update_column(:status, 'Removed')
    elsif can_have_entire_package_deprecated?
      result = platform_class.deprecation_info(name)
      if result[:is_deprecated]
        update_column(:status, 'Deprecated')
        update_column(:deprecation_reason, result[:message])
      end
    elsif removed
      update_column(:status, nil)
    end
  end

  def unique_repo_requirement_ranges
    repository_dependencies.select('repository_dependencies.requirements').distinct.pluck(:requirements)
  end

  def unique_package_requirement_ranges
    dependents.select('dependencies.requirements').distinct.pluck(:requirements)
  end

  def unique_requirement_ranges
    (unique_repo_requirement_ranges + unique_package_requirement_ranges).uniq
  end

  def potentially_outdated?
    current_version = SemanticRange.clean(latest_release_number)
    unique_requirement_ranges.compact.sort.any? do |range|
      begin
        !(SemanticRange.gtr(current_version, range, false, platform) ||
        SemanticRange.satisfies(current_version, range, false, platform))
      rescue
        false
      end
    end
  end

  def find_version!(version_name)
    version = if version_name == 'latest'
                versions.sort.first
              else
                versions.find_by_number(version_name)
              end

    raise ActiveRecord::RecordNotFound if version.nil?

    version
  end

  def reformat_repository_url
    repository_url = UrlParser.try_all(self.repository_url)
    update(repository_url: repository_url) if changed?
  end

  def github_name_with_owner
    GithubUrlParser.parse(repository_url) || GithubUrlParser.parse(homepage)
  end

  def gitlab_name_with_owner
    GitlabUrlParser.parse(repository_url) || GitlabUrlParser.parse(homepage)
  end

  def bitbucket_name_with_owner
    BitbucketUrlParser.parse(repository_url) || BitbucketUrlParser.parse(homepage)
  end

  def set_outdated_percentage
    major_versions = repository_dependencies.external.where(direct: true).active.source.select(&:latest_resolvable_version).group_by{|rd| rd.latest_resolvable_version.semantic_version.major }.sort_by{|v,rds| v }
    if major_versions.length > 1
      groups = major_versions
    else
      groups = repository_dependencies.external.where(direct: true).active.source.select(&:latest_resolvable_version).group_by{|rd| [rd.latest_resolvable_version.semantic_version.major, rd.latest_resolvable_version.semantic_version.minor] }.sort_by{|v,rds| v }
    end
    return if groups.empty?
    outdated = groups[0..-2].map(&:last).flatten.length
    outdated_percentage = (outdated.to_f/groups.sum(&:last).length*100).round(1)
    update_column(:outdated, outdated_percentage)
  end

  def self.set_outdated_percentage
    Package.internal.where('collab_dependent_repos_count > 0').includes(:versions).each(&:set_outdated_percentage)
  end

  def internal?
    organization.try(:internal?)
  end

  private

  def spdx_license
    licenses
      .downcase
      .sub(/^\(/, "")
      .sub(/\)$/, "")
      .split("or")
      .flat_map { |l| l.split("and") }
      .flat_map { |l| l.split(/[,\/]/) }
      .map(&Spdx.method(:find))
      .compact
      .map(&:id)
  end
end
