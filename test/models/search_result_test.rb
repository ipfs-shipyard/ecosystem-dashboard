require 'test_helper'

class SearchResultTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:search_query)
  end
end
