require 'test_helper'
require 'wasender_api'

class WasenderApi::ContactsTest < ActiveSupport::TestCase
  def setup
    @config = WasenderApi::WasenderConfig.new(personal_access_token: 'token', base_url: 'http://example.com')
    WasenderApi.stubs(:session_api_token).returns('token')
    @contacts = WasenderApi::Contacts.new(@config, 1)
    @request = mock('request')
    @contacts.instance_variable_set(:@request, @request)
  end

  test 'Real WasenderApi responds to stubbed methods' do
    assert_respond_to WasenderApi, :session_api_token
  end

  test 'list calls request.get with correct path' do
    @request.expects(:get).with('contacts').returns('ok')
    assert_equal 'ok', @contacts.list
  end

  test 'info calls request.get with correct contact_phone_number' do
    @request.expects(:get).with('contacts/1234567890').returns('ok')
    assert_equal 'ok', @contacts.info('1234567890')
  end

  test 'picture calls request.get with correct contact_phone_number' do
    @request.expects(:get).with('contacts/1234567890/picture').returns('ok')
    assert_equal 'ok', @contacts.picture('1234567890')
  end

  test 'block calls request.post with correct contact_phone_number' do
    @request.expects(:post).with('contacts/1234567890/block').returns('ok')
    assert_equal 'ok', @contacts.block('1234567890')
  end

  test 'unblock calls request.post with correct contact_phone_number' do
    @request.expects(:post).with('contacts/1234567890/unblock').returns('ok')
    assert_equal 'ok', @contacts.unblock('1234567890')
  end
end
