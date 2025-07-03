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
    WasenderApi.stubs(:webhook_secret).returns(@webhook_secret)
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

  test 'returns 500 if WasenderApi.webhook_secret raises an error' do
    WasenderApi.unstub(:webhook_secret)
    WasenderApi.stubs(:webhook_secret).raises(RuntimeError.new('session unavailable'))
    post '/webhook', params: @payload, headers: @headers
    assert_response :internal_server_error
    body = JSON.parse(@response.body)
    assert_match(/Webhook secret unavailable: session unavailable/, body['error'])
  end
end
