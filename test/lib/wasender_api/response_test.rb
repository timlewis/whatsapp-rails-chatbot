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

  test 'data returns parsed body data' do
    response_with_data = WasenderApi::Response.new(OpenStruct.new(status: 200, body: '{"data":{"foo":"bar"}}', success?: true))
    assert_equal 'bar', response_with_data.data[:foo]
    assert_equal 'bar', response_with_data.data['foo']
  end

  test 'data returns empty hash if response is not successful' do
    unsuccessful_response = WasenderApi::Response.new(OpenStruct.new(status: 500, body: '{"error":"fail"}', success?: false))
    assert_equal({}, unsuccessful_response.data)
  end

  test 'data returns empty hash if body is blank' do
    blank_response = WasenderApi::Response.new(OpenStruct.new(status: 200, body: '', success?: true))
    assert_equal({}, blank_response.data)
  end
end
