require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  context 'associations' do
    should have_many(:events)
    should have_many(:issues)
    should have_many(:repositories)
    should have_many(:repository_dependencies)
    should have_many(:packages)
  end
end
