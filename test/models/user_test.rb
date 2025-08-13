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
  # test "the truth" do
  #   assert true
  # end
end
