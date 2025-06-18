# == Schema Information
#
# Table name: messages
#
#  id            :integer          not null, primary key
#  chat_id       :integer          not null
#  role          :string
#  content       :text
#  model_id      :string
#  input_tokens  :integer
#  output_tokens :integer
#  tool_call_id  :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_messages_on_chat_id       (chat_id)
#  index_messages_on_tool_call_id  (tool_call_id)
#

require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test 'should validate presence of role' do
    message = messages(:one)
    message.role = nil
    assert_not message.valid?
    assert_includes message.errors[:role], "can't be blank"
  end

  test 'should create a message with valid attributes' do
    message = messages(:one)
    message.chat = chats(:two)
    assert message.valid?
  end
end
