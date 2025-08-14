require 'test_helper'

class AdminUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = admin_users(:one)
    @other_admin = admin_users(:two)
    sign_in @admin_user
  end

  test 'should get index' do
    get admin_users_url
    assert_response :success
    assert_select 'h1', 'Admin Users'
    assert_select 'table tbody tr', AdminUser.count
  end

  test 'should get new' do
    get new_admin_user_url
    assert_response :success
    assert_select 'h1', 'Create Admin User'
    assert_select 'form'
  end

  test 'should create admin_user with valid params' do
    assert_difference('AdminUser.count') do
      post admin_users_url, params: {
        admin_user: {
          email_address: 'new@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    assert_redirected_to admin_users_url
    assert_equal 'Admin user was successfully created.', flash[:notice]
  end

  test 'should not create admin_user with invalid params' do
    assert_no_difference('AdminUser.count') do
      post admin_users_url, params: {
        admin_user: {
          email_address: '',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select '.bg-red-50'
  end

  test 'should not create admin_user with mismatched passwords' do
    assert_no_difference('AdminUser.count') do
      post admin_users_url, params: {
        admin_user: {
          email_address: 'new@example.com',
          password: 'password123',
          password_confirmation: 'different'
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test 'should destroy other admin_user' do
    assert_difference('AdminUser.count', -1) do
      delete admin_user_url(@other_admin)
    end

    assert_redirected_to admin_users_url
    assert_equal 'Admin user was successfully deleted.', flash[:notice]
  end

  test 'should not destroy current admin_user' do
    assert_no_difference('AdminUser.count') do
      delete admin_user_url(@admin_user)
    end

    assert_redirected_to admin_users_url
    assert_equal 'You cannot delete your own account.', flash[:alert]
  end

  test 'should require authentication for all actions' do
    sign_out

    get admin_users_url
    assert_redirected_to new_session_url

    get new_admin_user_url
    assert_redirected_to new_session_url

    post admin_users_url, params: { admin_user: { email_address: 'test@example.com' } }
    assert_redirected_to new_session_url

    delete admin_user_url(@other_admin)
    assert_redirected_to new_session_url
  end

  test 'should show last logged in information' do
    # Create a session for the other admin
    @other_admin.sessions.create!(user_agent: 'Test Browser', ip_address: '127.0.0.1')

    get admin_users_url
    assert_response :success
    assert_select 'td', text: /ago/
  end

  test 'should show never logged in for admin with no sessions' do
    # Ensure other admin has no sessions
    @other_admin.sessions.destroy_all

    get admin_users_url
    assert_response :success
    assert_select '.bg-gray-100', text: 'Never'
  end

  private

  def sign_in(admin_user)
    post session_url, params: {
      email_address: admin_user.email_address,
      password: 'password'
    }
  end

  def sign_out
    delete session_url if session[:session_id]
  end
end
