class Contributor < ApplicationRecord
  scope :core, -> { where(core: true) }
  scope :bot,  -> { where(bot: true) }
  scope :core_or_bot, -> { core.or(bot) }
end
