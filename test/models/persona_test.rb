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

require 'test_helper'

class PersonaTest < ActiveSupport::TestCase
  test 'should validate presence of name' do
    persona = personas(:one)
    persona.name = nil
    assert_not persona.valid?
    assert_includes persona.errors[:name], "can't be blank"
  end

  test 'should validate presence of description' do
    persona = personas(:one)
    persona.description = nil
    assert_not persona.valid?
    assert_includes persona.errors[:description], "can't be blank"
  end

  test 'should validate presence of base_prompt' do
    persona = personas(:one)
    persona.base_prompt = nil
    assert_not persona.valid?
    assert_includes persona.errors[:base_prompt], "can't be blank"
  end

  test 'should only allow one persona to be default' do
    persona1 = personas(:one)
    persona2 = personas(:two)
    persona1.config_default = true
    assert persona1.valid?
    assert persona1.save
    persona2.config_default = true
    assert_not persona2.valid?
    assert_includes persona2.errors[:config_default], 'has already been taken'
  end

  test 'default scope returns only personas with config_default true' do
    # Set one persona as default
    persona = personas(:one)
    persona.update!(config_default: true)
    # Ensure the scope returns only the default persona
    defaults = Persona.default
    assert_includes defaults, persona
    assert defaults.all? { |p| p.config_default }, 'All returned personas should have config_default true'
  end
end
