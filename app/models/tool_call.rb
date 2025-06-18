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

class ToolCall < ApplicationRecord
  acts_as_tool_call # ruby-llm helper
  belongs_to :message
  validates :tool_call_id, uniqueness: true
end
