require 'test_helper'
require 'wasender_api'

class WasenderApi::MessagesTest < ActiveSupport::TestCase
  def setup
    @phone_number = '555'
    @config = WasenderApi::WasenderConfig.new(
      personal_access_token: 'token',
      base_url: 'https://api.example.com',
      phone_number: @phone_number
    )
    WasenderApi.stubs(:session_api_token).returns('token')
    @messages = WasenderApi::Messages.new(@config)
    @request = mock('request')
    @messages.instance_variable_set(:@request, @request)
  end

  test 'Real WasenderApi responds to stubbed methods' do
    assert_respond_to WasenderApi, :session_api_token
    assert_respond_to WasenderApi, :get_session_id
  end

  test 'send_text validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', text: 'hi').returns('ok')
    assert_equal 'ok', @messages.send_text({ to: '123', text: 'hi' })
  end

  test 'send_text raises error if payload doesnt include :text key' do
    assert_raises(ArgumentError, 'payload must include :text key') do
      @messages.send_text({ to: '123' })
    end
  end

  test 'send_text raises error if payload includes :text key but the value is not present' do
    assert_raises(ArgumentError, 'payload :text must be present') do
      @messages.send_text({ to: '123', text: '' })
    end
  end

  test 'send_image validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', imageUrl: 'http://img').returns('ok')
    assert_equal 'ok', @messages.send_image({ to: '123', imageUrl: 'http://img' })
  end

  test 'send_video validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', videoUrl: 'http://vid').returns('ok')
    assert_equal 'ok', @messages.send_video({ to: '123', videoUrl: 'http://vid' })
  end

  test 'send_document validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', documentUrl: 'http://doc').returns('ok')
    assert_equal 'ok', @messages.send_document({ to: '123', documentUrl: 'http://doc' })
  end

  test 'send_audio validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', audioUrl: 'http://aud').returns('ok')
    assert_equal 'ok', @messages.send_audio({ to: '123', audioUrl: 'http://aud' })
  end

  test 'send_sticker validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', stickerUrl: 'http://sticker').returns('ok')
    assert_equal 'ok', @messages.send_sticker({ to: '123', stickerUrl: 'http://sticker' })
  end

  test 'send_contact validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', contact: { name: 'n', phone: 'p' }).returns('ok')
    assert_equal 'ok', @messages.send_contact({ to: '123', contact: { name: 'n', phone: 'p' } })
  end

  test 'send_location validates payload and calls request.post with correct params' do
    @request.expects(:post).with('send-message', to: '123', location: { latitude: 1.0, longitude: 2.0, name: 'n', address: 'a' }).returns('ok')
    assert_equal 'ok', @messages.send_location({ to: '123', location: { latitude: 1.0, longitude: 2.0, name: 'n', address: 'a' } })
  end
end
