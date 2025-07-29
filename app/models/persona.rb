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
#
# Indexes
#
#  index_personas_on_config_default  (config_default) UNIQUE
#

class Persona < ApplicationRecord
  validates :name, presence: true
  validates :description, presence: true
  validates :base_prompt, presence: true

  # Ensure that only one persona can be set as the default
  validates :config_default, uniqueness: { conditions: -> { where(config_default: true) } }

  scope :default, -> { where(config_default: true) }
end
