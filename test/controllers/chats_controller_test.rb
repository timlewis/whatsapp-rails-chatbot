require 'test_helper'

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chat = chats(:one)
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get chats_url
    assert_response :success
  end

  test 'should get show' do
    get chat_url(@chat)
    assert_response :success
  end

  test 'should filter out system messages in show view' do
    # Create messages with different roles
    @chat.messages.create!(role: 'user', content: 'Hello from user', model_id: 'test-model')
    @chat.messages.create!(role: 'assistant', content: 'Hi there from assistant!', model_id: 'test-model')
    @chat.messages.create!(role: 'system', content: 'You are a helpful assistant system prompt.', model_id: 'test-model')

    get chat_url(@chat)
    assert_response :success

    # Check that user and assistant messages are displayed
    assert_select 'div', text: /Hello from user/
    assert_select 'div', text: /Hi there from assistant!/

    # Check that system message is NOT displayed in the conversation
    assert_select 'div', text: /You are a helpful assistant system prompt/, count: 0
  end
end
