require "test_helper"

class DependencyEventTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:repository)
    should belong_to(:package)
  end
end
