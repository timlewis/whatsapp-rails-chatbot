# == Schema Information
#
# Table name: chats
#
#  id         :integer          not null, primary key
#  model_id   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Chat < ApplicationRecord
  acts_as_chat # ruby-llm helper

  validates :model_id, presence: true, inclusion: { in: AVAILABLE_MODEL_IDS }
end
