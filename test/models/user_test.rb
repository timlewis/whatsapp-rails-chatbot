# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  whatsapp_number :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_whatsapp_number  (whatsapp_number) UNIQUE
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'should validate presence of whatsapp_number' do
    user = users(:one)
    user.whatsapp_number = nil
    assert_not user.valid?
    assert_includes user.errors[:whatsapp_number], "can't be blank"
  end

  test 'should validate uniqueness of whatsapp_number' do
    user1 = users(:one)
    user2 = User.new(whatsapp_number: user1.whatsapp_number)
    assert_not user2.valid?
    assert_includes user2.errors[:whatsapp_number], 'has already been taken'
  end
end
