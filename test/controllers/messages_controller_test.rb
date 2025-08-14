require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:one)
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get messages_url
    assert_response :success
  end

  test 'should get show' do
    get message_url(@message)
    assert_response :success
  end
end
