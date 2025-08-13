require "test_helper"

class ToolCallsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tool_calls_index_url
    assert_response :success
  end

  test "should get show" do
    get tool_calls_show_url
    assert_response :success
  end
end
