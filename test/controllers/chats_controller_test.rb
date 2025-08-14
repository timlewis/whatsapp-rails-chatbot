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
end
