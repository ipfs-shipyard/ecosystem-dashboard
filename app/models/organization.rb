class Organization < ApplicationRecord
  validates_presence_of :name

  scope :internal, -> { where(internal: true) }
  scope :collaborator, -> { where(collaborator: true) }

  def self.import_internal_orgs
    Issue::INTERNAL_ORGS.each do |name|
      Organization.find_or_create_by(name: name, internal: true, collaborator: false)
    end
  end

  def self.import_collaborator_orgs
    Repository.external.group(:org).count.keys.each do |name|
      Organization.find_or_create_by(name: name, internal: false, collaborator: true)
    end
  end
end
