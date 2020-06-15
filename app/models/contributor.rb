class Contributor < ApplicationRecord
  scope :core, -> { where(core: true) }
  scope :bot,  -> { where(bot: true) }
  scope :core_or_bot, -> { core.or(bot) }


  def self.import_bots
    Issue::BOTS.each do |login|
      Contributor.find_or_create_by(github_username: login, core: false, bot: true)
    end
  end

  def self.import_core_contributors
    Issue::CORE_CONTRIBUTORS.each do |login|
      Contributor.find_or_create_by(github_username: login, core: true, bot: false)
    end
  end
end
