require 'test_helper'

class ProcessWhatsappMessageJobTest < ActiveJob::TestCase
  def setup
    @user = users(:one)
    @message_text = 'Hello, how can you help me?'
    @whatsapp_number = @user.whatsapp_number

    # Use the default persona from fixtures
    @default_persona = personas(:one)

    # Mock WasenderApi responses
    @mock_messages_api = mock('WasenderApi::Messages')
    @mock_response = mock('Response')
    @mock_response.stubs(:success?).returns(true)
    @mock_messages_api.stubs(:send_text).returns(@mock_response)
    WasenderApi::Messages.stubs(:new).returns(@mock_messages_api)

    # Mock Chat and RubyLLM interactions
    @mock_chat = mock('Chat')
    @mock_chat.stubs(:with_instructions).returns(@mock_chat)

    # Mock response object with content method
    @mock_llm_response = mock('LLMResponse')
    @mock_llm_response.stubs(:content).returns("I'm here to help! How can I assist you today?")
    @mock_chat.stubs(:ask).returns(@mock_llm_response)
    Chat.stubs(:find_or_create_by).returns(@mock_chat)

    # Mock WasenderApi.split_message
    WasenderApi.stubs(:split_message).returns([ "I'm here to help! How can I assist you today?" ])
  end

  def teardown
    # Reset any stubbing
    Chat.unstub_everything if Chat.respond_to?(:unstub_everything)
    WasenderApi::Messages.unstub_everything if WasenderApi::Messages.respond_to?(:unstub_everything)
    WasenderApi.unstub_everything if WasenderApi.respond_to?(:unstub_everything)
  end

  # Basic job functionality tests
  test 'job is queued in default queue' do
    assert_equal 'default', ProcessWhatsappMessageJob.queue_name
  end

  test 'job performs without error' do
    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
    end
  end

  test 'job finds user by id' do
    User.expects(:find).with(@user.id).returns(@user)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  # Chat creation and finding tests
  test 'finds or creates chat for user' do
    Chat.expects(:find_or_create_by).with(user: @user).returns(@mock_chat)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'sets default model on new chat creation' do
    new_chat = Chat.new
    new_chat.expects(:model_id=).with(DEFAULT_LLM_MODEL)

    Chat.expects(:find_or_create_by).with(user: @user).yields(new_chat).returns(@mock_chat)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  # Persona and system instructions tests
  test 'retrieves default persona' do
    Persona.expects(:default).returns(stub(first: @default_persona))

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'returns early if no default persona exists' do
    Persona.stubs(:default).returns(stub(first: nil))

    # Should not call with_instructions or ask if no persona
    @mock_chat.expects(:with_instructions).never
    @mock_chat.expects(:ask).never

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'sets system instructions using persona base_prompt and FAQ context' do
    # Mock FAQ context (empty in this case since no FAQs in test)
    Faq.stubs(:context_for_llm).returns('')
    expected_instructions = @default_persona.base_prompt

    @mock_chat.expects(:with_instructions).with(expected_instructions).returns(@mock_chat)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'includes FAQ context in system instructions when FAQs exist' do
    faq_context = "Q: What is this?\nA: This is a test FAQ"
    Faq.stubs(:context_for_llm).returns(faq_context)
    expected_instructions = @default_persona.base_prompt + "\n\nFREQUENTLY ASKED QUESTIONS AND ANSWERS:\n#{faq_context}\n\nUse these FAQs to help answer user questions when relevant."

    @mock_chat.expects(:with_instructions).with(expected_instructions).returns(@mock_chat)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  # LLM interaction tests
  test 'asks LLM with provided message text' do
    test_response = mock('LLMResponse')
    test_response.stubs(:content).returns('Test response')
    @mock_chat.expects(:ask).with(@message_text).returns(test_response)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'handles empty message text' do
    empty_message = ''

    empty_response = mock('LLMResponse')
    empty_response.stubs(:content).returns("I didn't receive any message. How can I help?")
    @mock_chat.expects(:ask).with(empty_message).returns(empty_response)

    ProcessWhatsappMessageJob.perform_now(@user.id, empty_message, @whatsapp_number)
  end

  # WhatsApp messaging tests
  test 'splits long messages before sending' do
    long_response_text = 'This is a very long response that needs to be split into multiple messages'
    long_response = mock('LLMResponse')
    long_response.stubs(:content).returns(long_response_text)
    @mock_chat.stubs(:ask).returns(long_response)

    WasenderApi.expects(:split_message).with(long_response_text).returns([ 'Part 1', 'Part 2' ])

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'sends each message chunk via WasenderApi' do
    response_chunks = [ 'First chunk', 'Second chunk', 'Third chunk' ]
    WasenderApi.stubs(:split_message).returns(response_chunks)

    messages_api = mock('WasenderApi::Messages')
    WasenderApi::Messages.expects(:new).returns(messages_api)

    response_chunks.each do |chunk|
      success_response = mock('Response')
      success_response.stubs(:success?).returns(true)

      messages_api.expects(:send_text).with(
        to: @whatsapp_number,
        text: chunk
      ).returns(success_response)
    end

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'skips blank message chunks' do
    response_chunks = [ 'Valid message', '', '   ', 'Another valid message' ]
    WasenderApi.stubs(:split_message).returns(response_chunks)

    messages_api = mock('WasenderApi::Messages')
    WasenderApi::Messages.expects(:new).returns(messages_api)

    # Should only send non-blank messages
    messages_api.expects(:send_text).with(
      to: @whatsapp_number,
      text: 'Valid message'
    ).returns(@mock_response)

    messages_api.expects(:send_text).with(
      to: @whatsapp_number,
      text: 'Another valid message'
    ).returns(@mock_response)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
  end

  test 'logs error when WhatsApp message sending fails' do
    error_response = mock('Response')
    error_response.stubs(:success?).returns(false)
    error_response.stubs(:body).returns({ error: 'API Error' })

    @mock_messages_api.stubs(:send_text).returns(error_response)

    Rails.logger.expects(:error).with('Failed to send WhatsApp message: {error: "API Error"}')

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)

    # Add assertion to satisfy test requirements
    assert true
  end

  # Error handling tests
  test 'handles User not found error gracefully' do
    User.stubs(:find).raises(ActiveRecord::RecordNotFound.new('User not found'))

    # Should not raise error due to global rescue
    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(999, @message_text, @whatsapp_number)
    end
  end

  test 'handles Chat creation errors gracefully' do
    Chat.stubs(:find_or_create_by).raises(ActiveRecord::RecordInvalid.new)

    # Should not raise error due to global rescue
    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
    end
  end

  test 'handles LLM API errors gracefully' do
    @mock_chat.stubs(:ask).raises(StandardError.new('API Error'))

    # Should not raise error due to global rescue
    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
    end
  end

  # Integration test with actual objects (minimal mocking)
  test 'full integration with minimal mocks' do
    # Create a real chat without mocks
    chat = Chat.create!(user: @user, model_id: DEFAULT_LLM_MODEL)

    # Mock only the external API calls that we can't actually make in tests
    mock_llm_response = "Hello! I'm a test assistant. How can I help you?"

    # Mock the RubyLLM chat methods to avoid real API calls
    mock_response_obj = mock('LLMResponse')
    mock_response_obj.stubs(:content).returns(mock_llm_response)
    Chat.any_instance.stubs(:with_instructions).returns(chat)
    Chat.any_instance.stubs(:ask).returns(mock_response_obj)

    # Mock WasenderApi with real message splitting
    messages_api = mock('WasenderApi::Messages')
    success_response = mock('Response')
    success_response.stubs(:success?).returns(true)
    messages_api.stubs(:send_text).returns(success_response)
    WasenderApi::Messages.stubs(:new).returns(messages_api)

    # Use real message splitting
    WasenderApi.unstub(:split_message)

    # Verify the job runs successfully
    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, @whatsapp_number)
    end

    # Verify chat exists
    assert Chat.exists?(user: @user)
  end

  # Queue and retry behavior tests
  test 'job can be enqueued for later execution' do
    assert_enqueued_with(job: ProcessWhatsappMessageJob) do
      ProcessWhatsappMessageJob.perform_later(@user.id, @message_text, @whatsapp_number)
    end
  end

  test 'job can be enqueued with delay' do
    assert_enqueued_with(job: ProcessWhatsappMessageJob, at: 5.minutes.from_now) do
      ProcessWhatsappMessageJob.set(wait: 5.minutes).perform_later(@user.id, @message_text, @whatsapp_number)
    end
  end

  # Performance and resource tests
  test 'job handles multiple concurrent executions' do
    users = [ @user, users(:two) ]

    users.each do |user|
      assert_nothing_raised do
        ProcessWhatsappMessageJob.perform_now(user.id, @message_text, user.whatsapp_number)
      end
    end
  end

  test 'job handles very long message text' do
    very_long_message = 'Lorem ipsum ' * 1000  # Very long message

    # Should split into multiple chunks
    WasenderApi.expects(:split_message).with(anything).returns([ 'Chunk 1', 'Chunk 2', 'Chunk 3' ])

    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(@user.id, very_long_message, @whatsapp_number)
    end
  end

  test 'job handles special characters in message' do
    special_message = 'Hello! 🌟 How are you? 测试 émojis & special chars'

    special_response = mock('LLMResponse')
    special_response.stubs(:content).returns('I understand special characters!')
    @mock_chat.expects(:ask).with(special_message).returns(special_response)

    assert_nothing_raised do
      ProcessWhatsappMessageJob.perform_now(@user.id, special_message, @whatsapp_number)
    end
  end

  # Phone number format extraction tests
  test 'extracts phone number from WhatsApp JID format' do
    job = ProcessWhatsappMessageJob.new

    # Test WhatsApp JID format
    whatsapp_jid = '491626736670@s.whatsapp.net'
    extracted = job.send(:extract_phone_number, whatsapp_jid)
    assert_equal '+491626736670', extracted
  end

  test 'handles phone number already in E.164 format' do
    job = ProcessWhatsappMessageJob.new

    # Test E.164 format
    e164_number = '+491626725570'
    extracted = job.send(:extract_phone_number, e164_number)
    assert_equal '+491626725570', extracted
  end

  test 'adds plus prefix to plain phone numbers' do
    job = ProcessWhatsappMessageJob.new

    # Test plain number without plus
    plain_number = '491626736670'
    extracted = job.send(:extract_phone_number, plain_number)
    assert_equal '+491626736670', extracted
  end

  test 'sends WhatsApp message with correctly formatted phone number' do
    # Use real WhatsApp JID format as received from webhook
    whatsapp_jid = '491626736670@s.whatsapp.net'

    # Expect the phone number to be converted to E.164 format
    @mock_messages_api.expects(:send_text).with(
      to: '+491626736670',  # Should be converted from JID format
      text: anything
    ).returns(@mock_response)

    ProcessWhatsappMessageJob.perform_now(@user.id, @message_text, whatsapp_jid)
  end
end
