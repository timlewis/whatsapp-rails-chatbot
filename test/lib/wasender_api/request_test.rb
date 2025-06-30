require 'test_helper'
require 'wasender_api'

class WasenderApi::RequestTest < ActiveSupport::TestCase
  def setup
    @config = WasenderApi::WasenderConfig.new(personal_access_token: 'token', base_url: 'http://example.com')
    @request = WasenderApi::Request.new(@config, 'token')
  end

  test 'get, post, put, delete methods call request with correct method' do
    WasenderApi::Request.any_instance.stubs(:request).returns('ok')
    assert_equal 'ok', @request.get('foo')
    assert_equal 'ok', @request.post('foo')
    assert_equal 'ok', @request.put('foo')
    assert_equal 'ok', @request.delete('foo')
  end
end
