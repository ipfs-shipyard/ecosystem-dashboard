require 'test_helper'

class IssueTest < ActiveSupport::TestCase
  context 'associations' do
    should belong_to(:repository).optional 
    should belong_to(:contributor).optional 
    should belong_to(:organization).optional 
  end
end
