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

class AdminUser < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def last_logged_in_at
    sessions.order(:created_at).last&.created_at
  end
end
