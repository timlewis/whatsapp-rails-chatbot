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

  test 'should validate email format when provided' do
    persona = personas(:one)
    persona.email = 'invalid-email'
    assert_not persona.valid?
    assert_includes persona.errors[:email], 'is invalid'

    persona.email = 'valid@example.com'
    assert persona.valid?
  end

  test 'should allow blank email' do
    persona = personas(:one)
    persona.email = ''
    assert persona.valid?
  end

  test 'contact_instruction returns correct message based on contact methods' do
    persona = personas(:one)
    # Test with no contact methods
    persona.phone_number = nil
    persona.email = nil
    assert_equal "If you don't know an answer, please apologize.", persona.contact_instruction

    # Test with only phone number
    persona.phone_number = '+1234567890'
    persona.email = nil
    assert_equal "If you don't know an answer, please apologize and ask the customer to phone us at +1234567890.", persona.contact_instruction

    # Test with only email
    persona.phone_number = nil
    persona.email = 'support@example.com'
    assert_equal "If you don't know an answer, please apologize and ask the customer to send us an email at support@example.com.", persona.contact_instruction

    # Test with both contact methods
    persona.phone_number = '+1234567890'
    persona.email = 'support@example.com'
    assert_equal "If you don't know an answer, please apologize and ask the customer to phone us at +1234567890 or send us an email at support@example.com.", persona.contact_instruction
  end
end
