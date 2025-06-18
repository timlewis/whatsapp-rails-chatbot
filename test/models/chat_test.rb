# == Schema Information
#
# Table name: chats
#
#  id         :integer          not null, primary key
#  model_id   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test 'should validate presence of model_id' do
    chat = Chat.new
    assert_not chat.valid?
    assert_includes chat.errors[:model_id], "can't be blank"
  end

  test 'should validate inclusion of model_id in AVAILABLE_MODEL_IDS' do
    chat = Chat.new(model_id: 'invalid_model')
    assert_not chat.valid?
    assert_includes chat.errors[:model_id], 'is not included in the list'
  end

  test 'should create a chat with valid model_id' do
    chat = Chat.new(model_id: AVAILABLE_MODEL_IDS.sample)
    assert chat.valid?
    assert chat.save
  end
end
