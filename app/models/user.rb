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

class User < ApplicationRecord
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :tool_calls, through: :messages

  validates :whatsapp_number, presence: true, uniqueness: true
end
