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

class Message < ApplicationRecord
  acts_as_message # ruby-llm helper

  validates :role, presence: true

  belongs_to :chat
  belongs_to :tool_call, optional: true
  has_many_attached :attachments
end
