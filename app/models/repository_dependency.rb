class RepositoryDependency < ApplicationRecord
  include DependencyChecks

  belongs_to :manifest
  belongs_to :package, optional: true
  belongs_to :repository

  scope :with_package, -> { joins(:package).where('packages.id IS NOT NULL') }
  scope :without_package_id, -> { where(package_id: nil) }
  scope :with_package_name, -> { where("repository_dependencies.package_name <> ''") }
  scope :platform, ->(platform) { where('lower(repository_dependencies.platform) = ?', platform.try(:downcase)) }
  scope :kind, ->(kind) { where(kind: kind) }
  scope :active, -> { joins(:repository).where(repositories: {archived: false}) }
  scope :source, -> { joins(:repository).where(repositories: {fork: false}) }
  scope :direct, -> { where(direct: true) }
  scope :transitive, -> { where(direct: false) }

  scope :external, -> { where.not(repository_id: Repository.internal.pluck(:id)) }

  before_create :set_package_id

  delegate :latest_stable_release_number, :latest_release_number, :is_deprecated?, to: :package, allow_nil: true
  delegate :filepath, to: :manifest

  alias_method :latest_stable, :latest_stable_release_number
  alias_method :latest, :latest_release_number
  alias_method :deprecated, :is_deprecated?
  alias_method :outdated, :outdated?

  def name
    package_name
  end

  def self.internal
    with_package.where(packages: {repository_id: Repository.internal.pluck(:id)})
  end

  def find_package_id
    Package.find_best(platform, package_name&.strip)&.id
  end

  def compatible_license?
    return nil unless package
    return nil if package.normalized_licenses.empty?
    return nil if repository.license.blank?
    package.normalized_licenses.any? do |license|
      begin
        License::Compatibility.forward_compatibility(license, repository.license)
      rescue
        true
      end
    end
  end

  def set_package_id
    self.package_id = find_package_id unless package_id.present?
  end

  def update_package_id
    pkg_id = find_package_id
    update_column(:package_id, pkg_id) if pkg_id.present?
  end

  def package_name
    read_attribute(:package_name).try(:tr, " \n\t\r", '')
  end

  def direct?
    manifest.kind == 'manifest'
  end
end
