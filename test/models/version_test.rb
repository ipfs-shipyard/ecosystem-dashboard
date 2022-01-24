require 'test_helper'

class VersionTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:package)
    should have_many(:dependencies)
  end
end
