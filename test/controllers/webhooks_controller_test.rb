require 'test_helper'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @webhook_secret = 'testsecret'
    @headers = {
      'CONTENT_TYPE' => 'application/json',
      'X-Webhook-Signature' => @webhook_secret
    }
    @payload = {
      event: 'messages.received',
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

  test 'calls ProcessWebhook with correct parameters' do
    ProcessWebhook.expects(:run).with do |params|
      params[:event] == 'messages.received' &&
      params[:data]['key']['id'] == 'message-id-123' &&
      params[:data]['key']['fromMe'] == false &&
      params[:data]['key']['remoteJid'] == '+1234567890' &&
      params[:data]['message']['conversation'] == 'Hello, I have a question'
    end.returns(stub(valid?: true, result: { user: stub(whatsapp_number: '+1234567890', id: 1) }))

    post '/webhook', params: @payload, headers: @headers
    assert_response :success
  end

  test 'handles ProcessWebhook validation errors gracefully' do
    ProcessWebhook.expects(:run).returns(
      stub(valid?: false, errors: stub(full_messages: [ 'Event is not included in the list' ]))
    )

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
