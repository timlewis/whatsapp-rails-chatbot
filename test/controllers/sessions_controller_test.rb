require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = admin_users(:one)
  end

  test 'should get new' do
    get new_session_url
    assert_response :success
  end

  test 'should create session with valid credentials' do
    post session_url, params: {
      email_address: @admin_user.email_address,
      password: 'password'
    }
    assert_redirected_to root_url
    assert session[:session_id]
  end

  test 'should not create session with invalid credentials' do
    post session_url, params: {
      email_address: @admin_user.email_address,
      password: 'wrong_password'
    }
    assert_redirected_to new_session_url
  end

  test 'should destroy session' do
    sign_in_as(@admin_user)
    delete session_url
    assert_redirected_to new_session_url
  end
end
