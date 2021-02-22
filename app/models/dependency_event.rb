class DependencyEvent < ApplicationRecord
  belongs_to :repository
  belongs_to :package
end
