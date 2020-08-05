# frozen_string_literal: true

class Version < ApplicationRecord
  include Releaseable

  validates_presence_of :package_id, :number
  validates_uniqueness_of :number, scope: :package_id

  belongs_to :package
  counter_culture :package
  has_many :dependencies, dependent: :delete_all
  has_many :runtime_dependencies, -> { where kind: %w[runtime normal] }, class_name: "Dependency"

  before_save :update_spdx_expression
  after_commit :save_package, on: :create

  scope :newest_first, -> { order("versions.published_at DESC") }

  def save_package
    package.try(:forced_save)
  end

  def update_spdx_expression
    if original_license.is_a?(String)
      self.spdx_expression = original_license if Spdx.valid_spdx?(original_license)
    elsif original_license.is_a?(Array)
      possible_license = original_license.join(" AND ")
      self.spdx_expression = possible_license if Spdx.valid_spdx?(possible_license)
    end
  end

  def platform
    package.try(:platform)
  end

  def published_at
    @published_at ||= read_attribute(:published_at).presence || created_at
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.published_at <=> published_at
    else
      other.parsed_number <=> parsed_number
    end
  end

  def prerelease?
    if semantic_version && semantic_version.pre.present?
      true
    elsif platform.try(:downcase) == "rubygems"
      number.count("a-zA-Z") > 0
    else
      false
    end
  end

  def any_outdated_dependencies?
    @any_outdated_dependencies ||= runtime_dependencies.any?(&:outdated?)
  end

  def to_param
    package.to_param.merge(number: number)
  end

  def load_dependencies_tree(kind, date = nil)
    TreeResolver.new(self, kind, date).load_dependencies_tree
  end

  def related_tag
    return nil unless package&.repository

    @related_tag ||= package.repository.tags.find { |t| t.clean_number == clean_number }
  end

  def repository_url
    related_tag.try(:repository_url)
  end

  def related_versions
    @related_versions ||= package.try(:versions).try(:sort)
  end

  def related_versions_with_tags
    @related_versions_with_tags ||= related_versions.select(&:related_tag)
  end

  def version_index
    related_versions_with_tags.index(self)
  end

  def next_version
    related_versions_with_tags[version_index - 1]
  end

  def previous_version
    related_versions_with_tags[version_index + 1]
  end

  def diff_url
    return nil unless package&.repository && related_tag && previous_version && previous_version.related_tag

    package.repository.compare_url(previous_version.related_tag.number, related_tag.number)
  end

  def set_runtime_dependencies_count
    update_column(:runtime_dependencies_count, runtime_dependencies.count)
  end
end
