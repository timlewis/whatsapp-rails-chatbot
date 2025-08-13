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
  # test "the truth" do
  #   assert true
  # end
end
