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

require 'test_helper'

class ChatTest < ActiveSupport::TestCase
  test 'should validate inclusion of model_id in AVAILABLE_MODEL_IDS' do
    chat = chats(:one)
    chat.model_id = 'invalid_model'
    assert_not chat.valid?
    assert_includes chat.errors[:model_id], 'is not included in the list'
  end

  test 'should create a chat with valid model_id' do
    chat = chats(:one)
    chat.model_id = AVAILABLE_MODEL_IDS.sample
    assert chat.valid?
    assert chat.save
  end

  test 'should default model_id to DEFAULT_LLM_MODEL if not provided' do
    user = User.first || User.create!(whatsapp_number: '1234567890')
    chat = Chat.new(user: user)
    chat.valid?
    assert_equal DEFAULT_LLM_MODEL, chat.model_id
  end
end
