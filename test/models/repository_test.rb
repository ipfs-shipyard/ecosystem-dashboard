require 'test_helper'

class RepositoryTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:organization).optional 
    should have_many(:events)
    should have_many(:release_events)
    should have_many(:manifests)
    should have_many(:repository_dependencies)
    should have_many(:dependencies)
    should have_many(:dependency_events)
    should have_many(:tags)
    should have_many(:packages)
    should have_many(:issues)
    should have_many(:search_results)
  end
end
