# == Schema Information
#
# Table name: personas
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  description    :string           not null
#  base_prompt    :text             not null
#  config_default :boolean          default("0"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  phone_number   :string
#  email          :string
#
# Indexes
#
#  index_personas_on_config_default  (config_default) UNIQUE
#

class Persona < ApplicationRecord
  validates :name, presence: true
  validates :description, presence: true
  validates :base_prompt, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Ensure that only one persona can be set as the default
  validates :config_default, uniqueness: { conditions: -> { where(config_default: true) } }

  scope :default, -> { where(config_default: true) }

  def contact_instruction
    return "If you don't know an answer, please apologize." if phone_number.blank? && email.blank?

    contact_methods = []
    contact_methods << "phone us at #{phone_number}" if phone_number.present?
    contact_methods << "send us an email at #{email}" if email.present?

    "If you don't know an answer, please apologize and ask the customer to #{contact_methods.join(' or ')}."
  end
end
