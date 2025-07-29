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

  test 'split_message splits by newlines and max_lines' do
    text = "line1\nline2\nline3\nline4"
    chunks = WasenderApi.split_message(text, max_lines: 2, max_chars_per_line: 100)
    assert_equal [ "line1\nline2", "line3\nline4" ], chunks
  end

  test 'split_message splits long paragraphs by max_chars_per_line' do
    text = 'This is a very long paragraph that should be split into multiple lines for better readability on WhatsApp.'
    chunks = WasenderApi.split_message(text, max_lines: 2, max_chars_per_line: 30)
    # Each chunk should have at most 2 lines, each line at most 30 chars
    assert chunks.all? { |chunk| chunk.split("\n").size <= 2 }
    assert chunks.all? { |chunk| chunk.split("\n").all? { |line| line.length <= 30 } }
    assert chunks.join("\n").include?('readability on WhatsApp.')
  end

  test 'split_message handles empty string' do
    assert_equal [ '' ], WasenderApi.split_message('')
  end

  test 'split_message handles single short line' do
    assert_equal [ 'hello' ], WasenderApi.split_message('hello')
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
