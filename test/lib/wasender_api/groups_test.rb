require 'test_helper'
require 'wasender_api'

class WasenderApi::GroupsTest < ActiveSupport::TestCase
  def setup
    @config = WasenderApi::WasenderConfig.new(personal_access_token: 'token', base_url: 'http://example.com')
    WasenderApi.stubs(:session_api_token).returns('token')
    @groups = WasenderApi::Groups.new(@config, 1)
    @request = mock('request')
    @groups.instance_variable_set(:@request, @request)
  end
  test 'Real WasenderApi responds to stubbed methods' do
    assert_respond_to WasenderApi, :session_api_token
  end

  test 'list calls request.get with correct path' do
    @request.expects(:get).with('groups').returns('ok')
    assert_equal 'ok', @groups.list
  end

  test 'metadata calls request.get with correct group_jid' do
    @request.expects(:get).with('groups/123456789-987654321@g.us/metadata').returns('ok')
    assert_equal 'ok', @groups.metadata('123456789-987654321@g.us')
  end

  test 'participants calls request.get with correct group_jid' do
    @request.expects(:get).with('groups/123456789-987654321@g.us/participants').returns('ok')
    assert_equal 'ok', @groups.participants('123456789-987654321@g.us')
  end

  test 'add_participants calls request.post with correct params' do
    @request.expects(:post).with('groups/123456789-987654321@g.us/participants/add', participants: [ '111', '222' ]).returns('ok')
    assert_equal 'ok', @groups.add_participants('123456789-987654321@g.us', [ '111', '222' ])
  end

  test 'add_participants raises error if participants is not array' do
    assert_raises(ArgumentError, 'participants must be an array') do
      @groups.add_participants('123456789-987654321@g.us', 'not_array')
    end
  end

  test 'remove_participants calls request.post with correct params' do
    @request.expects(:post).with('groups/123456789-987654321@g.us/participants/remove', participants: [ '111', '222' ]).returns('ok')
    assert_equal 'ok', @groups.remove_participants('123456789-987654321@g.us', [ '111', '222' ])
  end

  test 'remove_participants raises error if participants is not array' do
    assert_raises(ArgumentError, 'participants must be an array') do
      @groups.remove_participants('123456789-987654321@g.us', 'not_array')
    end
  end

  test 'update_settings calls request.put with correct params' do
    @request.expects(:put).with('groups/123456789-987654321@g.us/settings', subject: 'New Subject').returns('ok')
    assert_equal 'ok', @groups.update_settings('123456789-987654321@g.us', { subject: 'New Subject' })
  end

  test 'update_settings raises error if settings is not a hash' do
    assert_raises(ArgumentError, 'settings must be a hash') do
      @groups.update_settings('123456789-987654321@g.us', 'not_hash')
    end
  end
end
