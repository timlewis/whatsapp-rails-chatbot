require 'test_helper'
require 'wasender_api'
require 'ostruct'

class WasenderApi::ResponseTest < ActiveSupport::TestCase
  def setup
    @mock_full_response = OpenStruct.new(status: 200, body: '{"foo":"bar"}', success?: true)
    @response = WasenderApi::Response.new(@mock_full_response)
  end

  test 'success? returns true for successful response' do
    assert @response.success?
  end

  test 'failure? returns false for successful response' do
    refute @response.failure?
  end

  test 'body parses JSON and returns hash with indifferent access' do
    assert_equal 'bar', @response.body[:foo]
    assert_equal 'bar', @response.body['foo']
  end

  test 'body returns empty hash if body is blank' do
    blank_response = WasenderApi::Response.new(OpenStruct.new(status: 200, body: '', success?: true))
    assert_equal({}, blank_response.body)
  end
end
