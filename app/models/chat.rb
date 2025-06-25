# == Schema Information
#
# Table name: chats
#
#  id         :integer          not null, primary key
#  model_id   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_chats_on_user_id  (user_id)
#

class Chat < ApplicationRecord
  acts_as_chat # ruby-llm helper
  belongs_to :user

  validates :model_id, presence: true, inclusion: { in: AVAILABLE_MODEL_IDS }
end
