require "test_helper"

class ContributorTest < ActiveSupport::TestCase
  context 'associations' do
    should have_many(:events)
    should have_many(:issues)
  end
end
