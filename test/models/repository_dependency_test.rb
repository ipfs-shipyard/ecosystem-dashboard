require 'test_helper'

class RepositoryDependencyTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:repository)
    should belong_to(:package).optional 
    should belong_to(:manifest)
  end
end
