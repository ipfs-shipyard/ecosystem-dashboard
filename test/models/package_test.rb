require 'test_helper'

class PackageTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:repository).optional 
    should have_one(:organization)
    should have_many(:dependencies)
    should have_many(:versions)
  end
end
