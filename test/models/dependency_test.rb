require 'test_helper'

class DependencyTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:package).optional 
    should belong_to(:version)
  end
end
