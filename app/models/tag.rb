class Tag < ApplicationRecord
  include Releaseable

  belongs_to :repository, touch: true
  validates_presence_of :name, :sha, :repository
  validates_uniqueness_of :name, scope: :repository_id

  scope :published, -> { where('published_at IS NOT NULL') }

  after_commit :save_packages

  def save_packages
    repository.try(:save_packages)
  end

  def has_packages?
    repository && repository.packages.without_versions.length > 0
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.number <=> number
    else
      other.parsed_number <=> parsed_number
    end
  end

  def prerelease?
    !!parsed_number.try(:pre)
  end

  def number
    name
  end

  def repository_url
    case repository.host_type
    when 'GitHub'
      "#{repository.url}/releases/tag/#{name}"
    when 'GitLab'
      "#{repository.url}/tags/#{name}"
    when 'Bitbucket'
      "#{repository.url}/commits/tag/#{name}"
    end
  end

  def related_tags
    repository.sorted_tags
  end

  def tag_index
    related_tags.index(self)
  end

  def next_tag
    related_tags[tag_index - 1]
  end

  def previous_tag
    related_tags[tag_index + 1]
  end

  alias_method :previous_version, :previous_tag

  def related_tag
    true
  end

  def diff_url
    return nil unless repository && previous_tag && previous_tag
    repository.compare_url(previous_tag.number, number)
  end

  def runtime_dependencies_count
    nil # tags can't have dependencies yet
  end
end
