require 'test_helper'
require 'wasender_api'

class WasenderApiTest < ActiveSupport::TestCase
  def setup
    @session_id = 42
    @api_token = 'api_token_123'
    @webhook_secret = 'webhook_secret_abc'
    @response = stub(success?: true, body: { data: { api_token: @api_token, webhook_secret: @webhook_secret, api_key: @api_token } })
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(@response)
    WasenderApi.session_hash = nil
  end

    test 'get_session_id returns session_id from session_id_hash if present' do
    WasenderApi.session_id_hash = { '12345' => 99 }
    assert_equal 99, WasenderApi.get_session_id('12345')
  end

  test 'get_session_id fetches and stores session_id if not in session_id_hash' do
    response = stub(success?: true, data: [ { id: 77, phone_number: '555', status: 'connected' }, { id: 88, phone_number: '999', status: 'disconnected' } ])
    WasenderApi::Session.any_instance.stubs(:list).returns(response)
    assert_equal 77, WasenderApi.get_session_id('555')
    assert_equal 77, WasenderApi.session_id_hash['555']
  end

  test 'get_session_id raises error if no connected session for phone number' do
    response = stub(success?: true, data: [ { id: 77, phone_number: '555', status: 'disconnected' } ])
    WasenderApi::Session.any_instance.stubs(:list).returns(response)
    WasenderApi.session_id_hash = nil
    assert_raises(RuntimeError, 'No session found for phone number: 555') do
      WasenderApi.get_session_id('555')
    end
  end

  test 'get_session_id raises error if response is not successful' do
    response = stub(success?: false, body: { message: 'fail' })
    WasenderApi::Session.any_instance.stubs(:list).returns(response)
    WasenderApi.session_id_hash = nil
    assert_raises(RuntimeError, 'Failed to retrieve sessions: fail') do
      WasenderApi.get_session_id('555')
    end
  end

  test 'session_api_token returns api_token from session_hash if present' do
    WasenderApi.session_hash = { @session_id => [ @api_token, @webhook_secret ] }
    assert_equal @api_token, WasenderApi.session_api_token(@session_id)
  end

  test 'session_api_token fetches and stores api_token if not in session_hash' do
    assert_equal @api_token, WasenderApi.session_api_token(@session_id)
    assert_equal [ @api_token, @webhook_secret ], WasenderApi.session_hash[@session_id]
  end

  test 'webhook_secret returns webhook_secret from session_hash if present' do
    WasenderApi.session_hash = { @session_id => [ @api_token, @webhook_secret ] }
    assert_equal @webhook_secret, WasenderApi.webhook_secret(@session_id)
  end

  test 'webhook_secret fetches and stores webhook_secret if not in session_hash' do
    assert_equal @webhook_secret, WasenderApi.webhook_secret(@session_id)
    assert_equal [ @api_token, @webhook_secret ], WasenderApi.session_hash[@session_id]
  end

  test 'session_api_token raises error if response is not successful' do
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(stub(success?: false, body: { error: 'fail' }))
    assert_raises(RuntimeError, 'Failed to retrieve session API token: fail') do
      WasenderApi.session_api_token(@session_id)
    end
  end

  test 'webhook_secret raises error if response is not successful' do
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(stub(success?: false, body: { error: 'fail' }))
    assert_raises(RuntimeError, 'Failed to retrieve session webhook secret: fail') do
      WasenderApi.webhook_secret(@session_id)
    end
  end

  test 'DEFAULT_CONFIG constant exists' do
    assert WasenderApi.const_defined?(:DEFAULT_CONFIG), 'DEFAULT_CONFIG constant should be defined on WasenderApi'
  end
end
