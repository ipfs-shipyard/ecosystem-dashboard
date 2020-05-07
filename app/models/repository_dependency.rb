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

  before_create :set_package_id

  alias_attribute :name, :package_name
  alias_attribute :latest_stable, :latest_stable_release_number
  alias_attribute :latest, :latest_release_number
  alias_attribute :deprecated, :is_deprecated?
  alias_method :outdated, :outdated?

  delegate :latest_stable_release_number, :latest_release_number, :is_deprecated?, to: :package, allow_nil: true
  delegate :filepath, to: :manifest

  def self.protocol
    with_package.where(packages: {repository_id: Repository.protocol.pluck(:id)})
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
    proj_id = find_package_id
    update_attribute(:package_id, proj_id) if proj_id.present?
  end

  def package_name
    read_attribute(:package_name).try(:tr, " \n\t\r", '')
  end
end
