require 'test_helper'
require 'wasender_api'

class WasenderApiTest < ActiveSupport::TestCase
  def setup
    @phone_number = '555'
    @session_id = 42
    @api_token = 'api_token_123'
    @webhook_secret = 'webhook_secret_abc'
    @config = WasenderApi::WasenderConfig.new(
      personal_access_token: 'token',
      base_url: 'https://api.example.com',
      phone_number: @phone_number
    )
    WasenderApi.session_id_hash = nil
    WasenderApi.session_hash = nil
  end

  test 'get_session_id returns session_id from cache if present' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    assert_equal @session_id, WasenderApi.get_session_id(@phone_number)
  end

  test 'get_session_id fetches and caches session_id if not present' do
    response = stub(success?: true, data: [ { id: @session_id, phone_number: @phone_number, status: 'connected' } ])
    WasenderApi::Session.any_instance.stubs(:list).returns(response)
    WasenderApi.session_id_hash = nil
    assert_equal @session_id, WasenderApi.get_session_id(@phone_number)
    assert_equal @session_id, WasenderApi.session_id_hash[@phone_number]
  end

  test 'get_session_id raises error if no connected session for phone number' do
    response = stub(success?: true, data: [ { id: 99, phone_number: @phone_number, status: 'disconnected' } ])
    WasenderApi::Session.any_instance.stubs(:list).returns(response)
    WasenderApi.session_id_hash = nil
    assert_raises(RuntimeError, /No session found for phone number: #{@phone_number}/) do
      WasenderApi.get_session_id(@phone_number)
    end
  end

  test 'get_session_id raises error if response is not successful' do
    response = stub(success?: false, body: { message: 'fail' })
    WasenderApi::Session.any_instance.stubs(:list).returns(response)
    WasenderApi.session_id_hash = nil
    assert_raises(RuntimeError, /Failed to retrieve sessions: fail/) do
      WasenderApi.get_session_id(@phone_number)
    end
  end

  test 'session_api_token returns api_token from cache if present' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    WasenderApi.session_hash = { @session_id => [ @api_token, @webhook_secret ] }
    assert_equal @api_token, WasenderApi.session_api_token(@config)
  end

  test 'session_api_token fetches and caches api_token if not present' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    WasenderApi.session_hash = nil
    details_response = stub(success?: true, data: { api_key: @api_token, webhook_secret: @webhook_secret })
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(details_response)
    assert_equal @api_token, WasenderApi.session_api_token(@config)
    assert_equal [ @api_token, @webhook_secret ], WasenderApi.session_hash[@session_id]
  end

  test 'session_api_token raises error if details response is not successful' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    WasenderApi.session_hash = nil
    details_response = stub(success?: false, body: { message: 'fail' })
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(details_response)
    assert_raises(RuntimeError, /Failed to retrieve session API token: fail/) do
      WasenderApi.session_api_token(@config)
    end
  end

  test 'webhook_secret returns webhook_secret from cache if present' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    WasenderApi.session_hash = { @session_id => [ @api_token, @webhook_secret ] }
    assert_equal @webhook_secret, WasenderApi.webhook_secret(@config)
  end

  test 'webhook_secret fetches and caches webhook_secret if not present' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    WasenderApi.session_hash = nil
    details_response = stub(success?: true, data: { api_key: @api_token, webhook_secret: @webhook_secret })
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(details_response)
    assert_equal @webhook_secret, WasenderApi.webhook_secret(@config)
    assert_equal [ @api_token, @webhook_secret ], WasenderApi.session_hash[@session_id]
  end

  test 'webhook_secret raises error if details response is not successful' do
    WasenderApi.session_id_hash = { @phone_number => @session_id }
    WasenderApi.session_hash = nil
    details_response = stub(success?: false, body: { message: 'fail' })
    WasenderApi::Session.any_instance.stubs(:details).with(@session_id).returns(details_response)
    assert_raises(RuntimeError, /Failed to retrieve session webhook secret: fail/) do
      WasenderApi.webhook_secret(@config)
    end
  end
end
