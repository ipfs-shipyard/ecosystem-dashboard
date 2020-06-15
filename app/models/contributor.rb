class Contributor < ApplicationRecord
  validates_presence_of :github_username

  has_many :events, foreign_key: :user, primary_key: :github_username
  has_many :issues, foreign_key: :user, primary_key: :github_username

  scope :core, -> { where(core: true) }
  scope :bot,  -> { where(bot: true) }
  scope :core_or_bot, -> { core.or(bot) }
end
