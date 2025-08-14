# == Schema Information
#
# Table name: admin_users
#
#  id              :integer          not null, primary key
#  email_address   :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_admin_users_on_email_address  (email_address) UNIQUE
#

require 'test_helper'

class AdminUserTest < ActiveSupport::TestCase
  test 'should return last logged in time from most recent session' do
    admin_user = admin_users(:one)
    admin_user.sessions.destroy_all

    # Create sessions with different timestamps
    first_time = 2.days.ago
    second_time = 1.day.ago

    first_session = admin_user.sessions.create!(user_agent: 'First', ip_address: '127.0.0.1')
    first_session.update_column(:created_at, first_time)

    second_session = admin_user.sessions.create!(user_agent: 'Second', ip_address: '127.0.0.1')
    second_session.update_column(:created_at, second_time)

    admin_user.reload
    assert_equal second_session.created_at.to_i, admin_user.last_logged_in_at.to_i
  end

  test 'should return nil when admin user has no sessions' do
    admin_user = admin_users(:one)
    admin_user.sessions.destroy_all

    assert_nil admin_user.last_logged_in_at
  end
end
