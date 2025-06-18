# == Schema Information
#
# Table name: tool_calls
#
#  id           :integer          not null, primary key
#  message_id   :integer          not null
#  tool_call_id :string           not null
#  name         :string           not null
#  arguments    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_tool_calls_on_message_id    (message_id)
#  index_tool_calls_on_tool_call_id  (tool_call_id) UNIQUE
#

require "test_helper"

class ToolCallTest < ActiveSupport::TestCase
  test 'should validate uniqueness of tool_call_id' do
    tool_call = tool_calls(:one)
    tool_call.tool_call_id = tool_calls(:two).tool_call_id
    assert_not tool_call.valid?
    assert_includes tool_call.errors[:tool_call_id], 'has already been taken'
  end
end
