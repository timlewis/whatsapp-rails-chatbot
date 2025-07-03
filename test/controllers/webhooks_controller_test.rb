require 'test_helper'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @webhook_secret = 'testsecret'
    @headers = {
      'CONTENT_TYPE' => 'application/json',
      'X-Webhook-Signature' => @webhook_secret
    }
    @payload = {
      event: 'messages.upsert',
      timestamp: Time.now.to_i,
      data: {
        key: {
          id: 'message-id-123',
          fromMe: false,
          remoteJid: '+1234567890'
        },
        message: {
          conversation: 'Hello, I have a question'
        }
      }
    }.to_json
    ENV['WEBHOOK_SECRET'] = @webhook_secret
  end

  test 'accepts valid messages.upsert webhook' do
    post '/webhook', params: @payload, headers: @headers
    assert_response :success
    assert_equal true, JSON.parse(@response.body)['received']
  end

  test 'rejects invalid signature' do
    @headers['X-Webhook-Signature'] = 'wrong'
    post '/webhook', params: @payload, headers: @headers
    assert_response :unauthorized
  end
end
