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
      sessionId: '4d72281317b3fc4bdb3f9c64f11004d9aa6ea8d3bcd2a044be7c89a0c1ea4998',
      data: {
        messages: {
          key: {
            remoteJid: '49163676670@s.whatsapp.net',
            fromMe: false,
            id: '3A44875A3256AFD6B920',
            senderLid: '12940887490729@lid'
          },
          messageTimestamp: 1756716993,
          pushName: 'Tim Lewis',
          broadcast: false,
          message: {
            conversation: 'Another day',
            messageContextInfo: {
              deviceListMetadata: {
                senderKeyHash: 'lhafBFwzf+POaQ==',
                senderTimestamp: '1754664910',
                recipientKeyHash: 'SuMuOZ5vWKpNMA==',
                recipientTimestamp: '1755526485'
              },
              deviceListMetadataVersion: 2,
              messageSecret: '1AP7G0G+MWkDD4W3kH5Hq6Tt4Q83obTPIHm7lIhN8TA='
            }
          },
          remoteJid: '49163676670@s.whatsapp.net',
          id: '3A44875A3256AFD6B920'
        }
      },
      timestamp: 1756716993156
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
      params[:data]['key']['id'] == '3A44875A3256AFD6B920' &&
      params[:data]['key']['fromMe'] == false &&
      params[:data]['key']['remoteJid'] == '49163676670@s.whatsapp.net' &&
      params[:data]['message']['conversation'] == 'Another day'
    end.returns(stub(valid?: true, result: { user: stub(whatsapp_number: '49163676670@s.whatsapp.net', id: 1) }))

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
