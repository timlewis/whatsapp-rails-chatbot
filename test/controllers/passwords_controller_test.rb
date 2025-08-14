require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = admin_users(:one)
  end

  test 'should get new' do
    get new_password_url
    assert_response :success
  end

  test 'should create password reset' do
    post passwords_url, params: {
      email_address: @admin_user.email_address
    }
    assert_response :redirect
  end

  test 'should get edit current password when authenticated' do
    sign_in_as(@admin_user)
    get account_password_url
    assert_response :success
  end

  test 'should update current password when authenticated' do
    sign_in_as(@admin_user)
    patch account_password_url, params: {
      current_password: 'password',
      password: 'new_password',
      password_confirmation: 'new_password'
    }
    assert_response :redirect
  end

  test 'should not update current password with wrong current password' do
    sign_in_as(@admin_user)
    patch account_password_url, params: {
      current_password: 'wrong_password',
      password: 'new_password',
      password_confirmation: 'new_password'
    }
    assert_response :redirect
  end
end
