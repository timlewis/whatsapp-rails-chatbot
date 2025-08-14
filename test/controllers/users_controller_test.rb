require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get users_url
    assert_response :success
  end

  test 'should get show' do
    get user_url(@user)
    assert_response :success
  end

  test 'should get new' do
    get new_user_url
    assert_response :success
  end

  test 'should get edit' do
    get edit_user_url(@user)
    assert_response :success
  end

  test 'should create user' do
    assert_difference('User.count') do
      post users_url, params: {
        user: {
          whatsapp_number: '+12345678901'  # Use a unique number different from fixtures
        }
      }
    end
    assert_redirected_to user_url(User.last)
  end

  test 'should update user' do
    patch user_url(@user), params: {
      user: {
        whatsapp_number: @user.whatsapp_number
      }
    }
    assert_redirected_to user_url(@user)
  end

  test 'should handle destroy user with foreign key constraints' do
    # Create a user without dependent records
    user_without_deps = User.create!(whatsapp_number: '+9999999999')

    assert_difference('User.count', -1) do
      delete user_url(user_without_deps)
    end
    assert_redirected_to users_url
  end
end
