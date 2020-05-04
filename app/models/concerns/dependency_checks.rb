module DependencyChecks
  extend ActiveSupport::Concern

  def incompatible_license?
    compatible_license? == false
  end

  def outdated?
    return nil unless valid_requirements? && package && package.latest_stable_release_number
    !(SemanticRange.satisfies(SemanticRange.clean(package.latest_stable_release_number), semantic_requirements, false, platform) ||
      SemanticRange.satisfies(SemanticRange.clean(package.latest_release_number), semantic_requirements, false, platform) ||
      SemanticRange.ltr(SemanticRange.clean(package.latest_release_number), semantic_requirements, false, platform))
  rescue
    nil
  end

  def semantic_requirements
    case platform.downcase
    when 'elm'
      numbers = requirements.split('<= v')
      ">=#{numbers[0].strip} #{numbers[1].strip}"
    else
      requirements
    end
  end

  def valid_requirements?
    !!SemanticRange.valid_range(semantic_requirements)
  end

  def latest_resolvable_version(date = nil)
    return nil unless package.present?
    versions = package.versions
    if date
      versions = versions.where('versions.published_at < ?', date)
    end
    version_numbers = versions.map {|v| SemanticRange.clean(v.number) }.compact
    number = SemanticRange.max_satisfying(version_numbers, semantic_requirements, false, platform)
    return nil unless number.present?

    versions.find{|v| SemanticRange.clean(v.number) == number }
  end

  def update_package
    return unless package_name.present? && package_manager
    package_manager.update(package_name)
  end

  def package_manager
    PackageManager::Base.find(platform)
  end
end
