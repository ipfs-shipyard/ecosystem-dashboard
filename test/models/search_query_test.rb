require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase
  context 'associations' do
    should have_many(:search_results)
  end
end
