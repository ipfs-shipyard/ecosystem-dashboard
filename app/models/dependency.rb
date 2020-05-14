class Dependency < ApplicationRecord
  include DependencyChecks

  belongs_to :version
  belongs_to :package, optional: true

  validates_presence_of :package_name, :version_id, :requirements, :platform

  scope :with_package, -> { joins(:package).where('packages.id IS NOT NULL') }
  scope :without_package_id, -> { where(package_id: nil) }
  scope :with_package_name, -> { where("dependencies.package_name <> ''") }
  scope :kind, ->(kind) { where(kind: kind) }
  scope :platform, ->(platform) { where('lower(dependencies.platform) = ?', platform.try(:downcase)) }

  # before_create :set_package_id

  alias_attribute :name, :package_name
  alias_attribute :latest_stable, :latest_stable_release_number
  alias_attribute :latest, :latest_release_number
  alias_attribute :deprecated, :is_deprecated?
  alias_method :outdated, :outdated?

  delegate :latest_stable_release_number, :latest_release_number, :is_deprecated?, :score, to: :package, allow_nil: true

  def filepath
    nil
  end

  def find_package_id
    Package.find_best(platform, package_name.strip)&.id
  end

  def compatible_license?
    return nil unless package
    return nil if package.normalized_licenses.empty?
    return nil if version.package.normalized_licenses.empty?
    package.normalized_licenses.any? do |license|
      version.package.normalized_licenses.any? do |other_license|
        begin
          License::Compatibility.forward_compatibility(license, other_license)
        rescue
          true
        end
      end
    end
  end

  def set_package_id
    self.package_id = find_package_id unless package_id.present?
  end

  def update_package_id
    pack_id = find_package_id
    update_attribute(:package_id, pack_id) if pack_id.present?
  end
end
