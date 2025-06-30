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
