require 'test_helper'

class ProcessWebhookTest < ActiveSupport::TestCase
  def setup
    @valid_data = {
      key: {
        id: 'message-id-123',
        fromMe: false,
        remoteJid: '+1234567890'
      },
      message: {
        conversation: 'Hello, I have a question'
      }
    }
  end

  # Event validation tests
  test 'validates presence of event' do
    result = ProcessWebhook.run(data: @valid_data)

    assert_not result.valid?
    assert_includes result.errors[:event], 'is required'
  end

  test 'validates event is in allowed list' do
    result = ProcessWebhook.run(event: 'invalid.event', data: @valid_data)

    assert_not result.valid?
    assert_includes result.errors[:event], 'is not included in the list'
  end

  test 'accepts valid events from WasenderApi::WEBHOOK_EVENTS' do
    WasenderApi::WEBHOOK_EVENTS.each do |event|
      result = ProcessWebhook.run(event: event, data: @valid_data)

      assert result.valid?, "Event '#{event}' should be valid but got errors: #{result.errors.full_messages}"
    end
  end

  # Data hash validation tests
  test 'validates presence of data' do
    result = ProcessWebhook.run(event: 'messages.upsert')

    assert_not result.valid?
    assert_includes result.errors[:data], 'is required'
  end

  test 'validates data is a hash' do
    result = ProcessWebhook.run(event: 'messages.upsert', data: 'invalid')

    assert_not result.valid?
    assert_includes result.errors[:data], 'is not a valid hash'
  end

  test 'validates presence of key in data' do
    invalid_data = @valid_data.dup
    invalid_data.delete(:key)

    result = ProcessWebhook.run(event: 'messages.upsert', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key"], 'is required'
  end

  test 'validates presence of message in data' do
    invalid_data = @valid_data.dup
    invalid_data.delete(:message)

    result = ProcessWebhook.run(event: 'messages.upsert', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.message"], 'is required'
  end

  test 'validates key contains required fields' do
    invalid_data = @valid_data.dup
    invalid_data[:key].delete(:id)

    result = ProcessWebhook.run(event: 'messages.upsert', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key.id"], 'is required'
  end

  test 'validates key fromMe is boolean' do
    invalid_data = @valid_data.dup
    invalid_data[:key][:fromMe] = 'not_boolean'

    result = ProcessWebhook.run(event: 'messages.upsert', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key.fromMe"], 'is not a valid boolean'
  end

  test 'validates key remoteJid is present' do
    invalid_data = @valid_data.dup
    invalid_data[:key].delete(:remoteJid)

    result = ProcessWebhook.run(event: 'messages.upsert', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key.remoteJid"], 'is required'
  end

  # User creation/finding tests
  test 'finds existing user by whatsapp_number' do
    existing_user = users(:one)
    data_with_existing_number = @valid_data.dup
    data_with_existing_number[:key][:remoteJid] = existing_user.whatsapp_number

    result = ProcessWebhook.run(event: 'messages.upsert', data: data_with_existing_number)

    assert result.valid?
    assert_equal existing_user, result.result[:user]
  end

  test 'creates new user when whatsapp_number does not exist' do
    new_number = '+9876543210'
    data_with_new_number = @valid_data.dup
    data_with_new_number[:key][:remoteJid] = new_number

    assert_difference 'User.count', 1 do
      result = ProcessWebhook.run(event: 'messages.upsert', data: data_with_new_number)

      assert result.valid?
      assert_equal new_number, result.result[:user].whatsapp_number
    end
  end

  test 'does not create duplicate users for same whatsapp_number' do
    new_number = '+5555555555'
    data_with_number = @valid_data.dup
    data_with_number[:key][:remoteJid] = new_number

    # First call should create user
    assert_difference 'User.count', 1 do
      result1 = ProcessWebhook.run(event: 'messages.upsert', data: data_with_number)
      assert result1.valid?
    end

    # Second call should find existing user, not create new one
    assert_no_difference 'User.count' do
      result2 = ProcessWebhook.run(event: 'messages.upsert', data: data_with_number)
      assert result2.valid?
      assert_equal new_number, result2.result[:user].whatsapp_number
    end
  end

  # Returned data structure tests
  test 'returns correct data structure when valid' do
    result = ProcessWebhook.run(event: 'messages.upsert', data: @valid_data)

    assert result.valid?
    assert_instance_of Hash, result.result
    assert_includes result.result.keys, :user
    assert_includes result.result.keys, :message_data
    assert_instance_of User, result.result[:user]
    assert result.result[:message_data].is_a?(Hash)
  end

  test 'user in result has correct whatsapp_number' do
    result = ProcessWebhook.run(event: 'messages.upsert', data: @valid_data)

    assert result.valid?
    assert_equal @valid_data[:key][:remoteJid], result.result[:user].whatsapp_number
  end

  test 'message_data in result contains key data' do
    result = ProcessWebhook.run(event: 'messages.upsert', data: @valid_data)

    assert result.valid?
    assert_equal @valid_data[:key][:id], result.result[:message_data][:key][:id]
    assert_equal @valid_data[:key][:fromMe], result.result[:message_data][:key][:fromMe]
    assert_equal @valid_data[:key][:remoteJid], result.result[:message_data][:key][:remoteJid]
    assert result.result[:message_data][:message].is_a?(Hash)
  end

  # Edge cases
  test 'handles string keys in data hash' do
    string_key_data = {
      'key' => {
        'id' => 'message-id-456',
        'fromMe' => true,
        'remoteJid' => '+1111111111'
      },
      'message' => {
        'conversation' => 'Test with string keys'
      }
    }

    result = ProcessWebhook.run(event: 'messages.upsert', data: string_key_data)

    assert result.valid?
    assert_equal '+1111111111', result.result[:user].whatsapp_number
  end

  test 'handles mixed key types in nested data' do
    mixed_data = {
      key: {
        'id' => 'message-id-789',
        fromMe: false,
        'remoteJid' => '+2222222222'
      },
      'message' => {
        conversation: 'Mixed key types'
      }
    }

    result = ProcessWebhook.run(event: 'messages.upsert', data: mixed_data)

    assert result.valid?
    assert_equal '+2222222222', result.result[:user].whatsapp_number
  end
end
