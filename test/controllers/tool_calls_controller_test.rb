require 'test_helper'

class ToolCallsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tool_call = tool_calls(:one)
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get tool_calls_url
    assert_response :success
  end

  test 'should get show' do
    get tool_call_url(@tool_call)
    assert_response :success
  end
end
