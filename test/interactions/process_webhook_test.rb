require 'test_helper'

class ProcessWebhookTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
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
    result = ProcessWebhook.run(event: 'messages.received')

    assert_not result.valid?
    assert_includes result.errors[:data], 'is required'
  end

  test 'validates data is a hash' do
    result = ProcessWebhook.run(event: 'messages.received', data: 'invalid')

    assert_not result.valid?
    assert_includes result.errors[:data], 'is not a valid hash'
  end

  test 'validates presence of key in data' do
    invalid_data = @valid_data.dup
    invalid_data.delete(:key)

    result = ProcessWebhook.run(event: 'messages.received', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key"], 'is required'
  end

  test 'validates presence of message in data' do
    invalid_data = @valid_data.dup
    invalid_data.delete(:message)

    result = ProcessWebhook.run(event: 'messages.received', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.message"], 'is required'
  end

  test 'validates key contains required fields' do
    invalid_data = @valid_data.dup
    invalid_data[:key].delete(:id)

    result = ProcessWebhook.run(event: 'messages.received', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key.id"], 'is required'
  end

  test 'validates key fromMe is boolean' do
    invalid_data = @valid_data.dup
    invalid_data[:key][:fromMe] = 'not_boolean'

    result = ProcessWebhook.run(event: 'messages.received', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key.fromMe"], 'is not a valid boolean'
  end

  test 'validates key remoteJid is present' do
    invalid_data = @valid_data.dup
    invalid_data[:key].delete(:remoteJid)

    result = ProcessWebhook.run(event: 'messages.received', data: invalid_data)

    assert_not result.valid?
    assert_includes result.errors[:"data.key.remoteJid"], 'is required'
  end

  # User creation/finding tests
  test 'finds existing user by whatsapp_number' do
    existing_user = users(:one)
    data_with_existing_number = @valid_data.dup
    data_with_existing_number[:key][:remoteJid] = existing_user.whatsapp_number

    result = ProcessWebhook.run(event: 'messages.received', data: data_with_existing_number)

    assert result.valid?
    assert_equal existing_user, result.result[:user]
  end

  test 'creates new user when whatsapp_number does not exist' do
    new_number = '+9876543210'
    data_with_new_number = @valid_data.dup
    data_with_new_number[:key][:remoteJid] = new_number

    assert_difference 'User.count', 1 do
      result = ProcessWebhook.run(event: 'messages.received', data: data_with_new_number)

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
      result1 = ProcessWebhook.run(event: 'messages.received', data: data_with_number)
      assert result1.valid?
    end

    # Second call should find existing user, not create new one
    assert_no_difference 'User.count' do
      result2 = ProcessWebhook.run(event: 'messages.received', data: data_with_number)
      assert result2.valid?
      assert_equal new_number, result2.result[:user].whatsapp_number
    end
  end

  # Returned data structure tests
  test 'returns correct data structure when valid' do
    result = ProcessWebhook.run(event: 'messages.received', data: @valid_data)

    assert result.valid?
    assert_instance_of Hash, result.result
    assert_includes result.result.keys, :user
    assert_includes result.result.keys, :message_data
    assert_instance_of User, result.result[:user]
    assert result.result[:message_data].is_a?(Hash)
  end

  test 'user in result has correct whatsapp_number' do
    result = ProcessWebhook.run(event: 'messages.received', data: @valid_data)

    assert result.valid?
    assert_equal @valid_data[:key][:remoteJid], result.result[:user].whatsapp_number
  end

  test 'message_data in result contains key data' do
    result = ProcessWebhook.run(event: 'messages.received', data: @valid_data)

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

    result = ProcessWebhook.run(event: 'messages.received', data: string_key_data)

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

    result = ProcessWebhook.run(event: 'messages.received', data: mixed_data)

    assert result.valid?
    assert_equal '+2222222222', result.result[:user].whatsapp_number
  end

  # Job enqueueing tests
  test 'enqueues ProcessWhatsappMessageJob for incoming text messages' do
    assert_enqueued_jobs 1, only: ProcessWhatsappMessageJob do
      result = ProcessWebhook.run(event: 'messages.received', data: @valid_data)
      assert result.valid?
    end
  end

  test 'does not enqueue job for messages from bot (fromMe: true)' do
    data_from_bot = @valid_data.dup
    data_from_bot[:key][:fromMe] = true

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data_from_bot)
      assert result.valid?
    end
  end

  test 'does not enqueue job when message text is blank' do
    data_no_text = @valid_data.dup
    data_no_text[:message] = {} # empty message should not be processed

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data_no_text)
      assert result.valid?
    end
  end

  test 'enqueues job with correct parameters' do
    user = users(:one)
    data_with_user = @valid_data.dup
    data_with_user[:key][:remoteJid] = user.whatsapp_number

    assert_enqueued_with(
      job: ProcessWhatsappMessageJob,
      args: [ user.id, 'Hello, I have a question', user.whatsapp_number ]
    ) do
      result = ProcessWebhook.run(event: 'messages.received', data: data_with_user)
      assert result.valid?
    end
  end

  # Message text extraction tests
  test 'extracts text from conversation message' do
    data = @valid_data.dup
    data[:message] = { conversation: 'Test conversation message' }

    assert_enqueued_jobs 1, only: ProcessWhatsappMessageJob do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
    end
  end

  test 'extracts text from extendedTextMessage' do
    data = @valid_data.dup
    data[:message] = {
      extendedTextMessage: {
        text: 'Extended text message'
      }
    }

    assert_enqueued_jobs 1, only: ProcessWhatsappMessageJob do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
    end
  end

  test 'sends response message for imageMessage and does not enqueue job' do
    data = @valid_data.dup
    data[:message] = {
      imageMessage: {
        url: 'https://example.com/image.jpg',
        caption: 'Image caption',
        mimetype: 'image/jpeg'
      }
    }

    # Mock WasenderApi::Messages
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).with({
      to: '+1234567890',
      text: 'Thank you for sending us this image, unfortunately we can only respond to Text messages at the moment'
    })
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  test 'sends response message for imageMessage without caption' do
    data = @valid_data.dup
    data[:message] = {
      imageMessage: {
        url: 'https://example.com/image.jpg',
        mimetype: 'image/jpeg'
      }
    }

    # Mock WasenderApi::Messages
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).with({
      to: '+1234567890',
      text: 'Thank you for sending us this image, unfortunately we can only respond to Text messages at the moment'
    })
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  test 'sends response message for videoMessage' do
    data = @valid_data.dup
    data[:message] = {
      videoMessage: {
        url: 'https://example.com/video.mp4',
        caption: 'Video description',
        mimetype: 'video/mp4'
      }
    }

    # Mock WasenderApi::Messages
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).with({
      to: '+1234567890',
      text: 'Thank you for sending us this video, unfortunately we can only respond to Text messages at the moment'
    })
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  test 'sends response message for audioMessage' do
    data = @valid_data.dup
    data[:message] = {
      audioMessage: {
        url: 'https://example.com/audio.mp3',
        mimetype: 'audio/mpeg'
      }
    }

    # Mock WasenderApi::Messages
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).with({
      to: '+1234567890',
      text: 'Thank you for sending us this audio, unfortunately we can only respond to Text messages at the moment'
    })
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  test 'sends response message for documentMessage' do
    data = @valid_data.dup
    data[:message] = {
      documentMessage: {
        url: 'https://example.com/document.pdf',
        caption: 'Document description',
        mimetype: 'application/pdf'
      }
    }

    # Mock WasenderApi::Messages
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).with({
      to: '+1234567890',
      text: 'Thank you for sending us this document, unfortunately we can only respond to Text messages at the moment'
    })
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  test 'sends response message for stickerMessage' do
    data = @valid_data.dup
    data[:message] = {
      stickerMessage: {
        url: 'https://example.com/sticker.webp',
        mimetype: 'image/webp'
      }
    }

    # Mock WasenderApi::Messages
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).with({
      to: '+1234567890',
      text: 'Thank you for sending us this sticker, unfortunately we can only respond to Text messages at the moment'
    })
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  test 'handles empty message object' do
    data = @valid_data.dup
    data[:message] = {}

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
    end
  end

  test 'handles system messages with messageStubType' do
    data = @valid_data.dup
    data[:messageStubType] = 1
    data[:messageStubParameters] = [ 'user joined' ]

    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:system_message]
    end
  end

  test 'handles WasenderApi errors gracefully when sending media response' do
    data = @valid_data.dup
    data[:message] = {
      imageMessage: {
        url: 'https://example.com/image.jpg',
        mimetype: 'image/jpeg'
      }
    }

    # Mock WasenderApi::Messages to raise an error
    messages_api_mock = mock('messages_api')
    messages_api_mock.expects(:send_text).raises(StandardError.new('API Error'))
    WasenderApi::Messages.expects(:new).returns(messages_api_mock)

    # Should not raise an error and should still return valid result
    assert_no_enqueued_jobs do
      result = ProcessWebhook.run(event: 'messages.received', data: data)
      assert result.valid?
      assert_equal true, result.result[:media_response_sent]
    end
  end

  private

  def match_any
    ->(arg) { true }
  end
end
