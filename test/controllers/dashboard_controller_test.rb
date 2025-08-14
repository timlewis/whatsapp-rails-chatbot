require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get root_url
    assert_response :success
  end
end
