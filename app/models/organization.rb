class Organization < ApplicationRecord
  validates_presence_of :name

  scope :internal, -> { where(internal: true) }
  scope :collaborator, -> { where(collaborator: true) }
end
