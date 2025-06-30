require 'test_helper'
require 'wasender_api'

class WasenderApi::SessionTest < ActiveSupport::TestCase
  def setup
    @config = WasenderApi::WasenderConfig.new(personal_access_token: 'token', base_url: 'http://example.com')
    @session = WasenderApi::Session.new(@config)
    @request = mock('request')
    @session.instance_variable_set(:@request, @request)
  end

  test 'list calls request.get with correct path' do
    @request.expects(:get).with('whatsapp-sessions').returns('ok')
    assert_equal 'ok', @session.list
  end

  test 'details calls request.get with correct path' do
    @request.expects(:get).with('whatsapp-sessions/123').returns('ok')
    assert_equal 'ok', @session.details(123)
  end

  test 'update calls request.put with correct path and payload' do
    @request.expects(:put).with('whatsapp-sessions/123', name: 'foo').returns('ok')
    assert_equal 'ok', @session.update(123, { name: 'foo' })
  end

  test 'create validates payload and calls request.post with correct params' do
    @request.expects(:post).with('whatsapp-sessions', name: 'foo', phone_number: '123', account_protection: true, log_messages: false).returns('ok')
    assert_equal 'ok', @session.create({ name: 'foo', phone_number: '123', account_protection: true, log_messages: false })
  end

  test 'connect calls request.post with correct path' do
    @request.expects(:post).with('whatsapp-sessions/123/connect').returns('ok')
    assert_equal 'ok', @session.connect(123)
  end

  test 'qrcode calls request.get with correct path' do
    @request.expects(:get).with('whatsapp-sessions/123/qrcode').returns('ok')
    assert_equal 'ok', @session.qrcode(123)
  end

  test 'create raises error if account_protection is nil' do
    error = assert_raises(ArgumentError) do
      @session.create({ name: 'foo', phone_number: '123', account_protection: nil, log_messages: false })
    end
    assert_match 'payload :account_protection must be present', error.message
  end
end
