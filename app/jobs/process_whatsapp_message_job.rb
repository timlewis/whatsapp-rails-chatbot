class ProcessWhatsappMessageJob < ApplicationJob
  queue_as :default

  def perform(user_id, message_text, whatsapp_number)
    Rails.logger.info("Processing WhatsApp message for user #{user_id}: #{message_text[0..100]}...")

    user = User.find(user_id)

    # Create or find existing chat for this user
    chat_record = Chat.find_or_create_by(user: user) do |chat|
      chat.model_id = DEFAULT_LLM_MODEL
    end

    # Get default persona's base prompt for system instructions
    default_persona = Persona.default.first
    unless default_persona
      Rails.logger.error('No default persona found. Cannot process message.')
      return
    end

    # Build system instructions combining persona and FAQ context
    system_instructions = build_system_instructions(default_persona)
    chat_record = chat_record.with_instructions(system_instructions)

    # Ask the LLM and get response
    Rails.logger.info("Querying LLM with persona: #{default_persona.name}")
    response = chat_record.ask(message_text)

    if response.present?
      Rails.logger.info("Received LLM response (#{response.content.length} chars), sending reply...")
      send_whatsapp_reply(whatsapp_number, response.content)
    else
      Rails.logger.warn("LLM returned empty response for message: #{message_text}")
    end

  rescue StandardError => e
    Rails.logger.error("Error processing WhatsApp message: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Send fallback message to user
    fallback_message = "Sorry, I'm having trouble processing your message right now. Please try again later."
    send_whatsapp_reply(whatsapp_number, fallback_message)
  end

  private

  def build_system_instructions(persona)
    instructions = persona.base_prompt.dup

    # Add FAQ context if any active FAQs exist
    faq_context = Faq.context_for_llm
    if faq_context.present?
      instructions += "\n\nFREQUENTLY ASKED QUESTIONS AND ANSWERS:\n#{faq_context}\n\nUse these FAQs to help answer user questions when relevant."
    end

    # Add contact instruction based on available contact methods
    instructions += "\n\n#{persona.contact_instruction}"

    instructions
  end

  def send_whatsapp_reply(whatsapp_number, message_text)
    message_chunks = WasenderApi.split_message(message_text)
    phone_number = extract_phone_number(whatsapp_number)
    messages_api = WasenderApi::Messages.new

    message_chunks.each_with_index do |chunk, index|
      next if chunk.blank?

      response = messages_api.send_text(
        to: phone_number,
        text: chunk
      )

      unless response.success?
        Rails.logger.error "Failed to send WhatsApp message: #{response.body}"
        break # Stop sending if one fails
      end

      # Add delay between chunks to respect WhatsApp rate limit (1 message per 5 seconds)
      if index < message_chunks.length - 1
        delay = rand(5.0..7.5) # Random delay between 5-7.5 seconds
        sleep(delay)
      end
    end
  end

  def extract_phone_number(whatsapp_jid)
    # Extract phone number from WhatsApp JID format
    # "491626736670@s.whatsapp.net" -> "+491626736670"
    if whatsapp_jid.include?('@')
      phone_part = whatsapp_jid.split('@').first
      phone_part.start_with?('+') ? phone_part : "+#{phone_part}"
    else
      whatsapp_jid.start_with?('+') ? whatsapp_jid : "+#{whatsapp_jid}"
    end
  end
end
