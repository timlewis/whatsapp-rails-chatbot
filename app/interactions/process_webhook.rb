class ProcessWebhook < ActiveInteraction::Base
  string :event
  integer :timestamp, default: nil
  hash :data do
    hash :key do
      string :id
      boolean :fromMe
      string :remoteJid
    end
    hash :message, strip: false do
      string :conversation, default: nil
      hash :extendedTextMessage, default: {} do
        string :text, default: nil
      end
      hash :imageMessage, default: {} do
        string :url, default: nil
        string :mimetype, default: nil
        string :caption, default: nil
        string :fileSha256, default: nil
        string :fileLength, default: nil
        string :mediaKey, default: nil
        string :mediaKeyTimestamp, default: nil
      end
      hash :videoMessage, default: {} do
        string :url, default: nil
        string :mimetype, default: nil
        string :caption, default: nil
        string :fileSha256, default: nil
        string :fileLength, default: nil
        string :mediaKey, default: nil
        string :mediaKeyTimestamp, default: nil
      end
      hash :audioMessage, default: {} do
        string :url, default: nil
        string :mimetype, default: nil
        string :fileSha256, default: nil
        string :fileLength, default: nil
        string :mediaKey, default: nil
        string :mediaKeyTimestamp, default: nil
      end
      hash :documentMessage, default: {} do
        string :url, default: nil
        string :mimetype, default: nil
        string :caption, default: nil
        string :fileSha256, default: nil
        string :fileLength, default: nil
        string :mediaKey, default: nil
        string :mediaKeyTimestamp, default: nil
      end
      hash :stickerMessage, default: {} do
        string :url, default: nil
        string :mimetype, default: nil
        string :fileSha256, default: nil
        string :fileLength, default: nil
        string :mediaKey, default: nil
        string :mediaKeyTimestamp, default: nil
      end
    end
    integer :messageStubType, default: nil
    array :messageStubParameters, default: []
  end

  validates :event, presence: true, inclusion: { in: WasenderApi::WEBHOOK_EVENTS }

  def execute
    user = find_or_create_user

    # Handle system messages (messageStubType) - don't process with AI
    if data[:messageStubType].present?
      Rails.logger.info("Received system message of type #{data[:messageStubType]} from #{user.whatsapp_number}. Stub params: #{data[:messageStubParameters]}")
      return {
        user: user,
        message_data: data,
        system_message: true
      }
    end

    # Skip messages from the bot itself
    return { user: user, message_data: data, system_message: false } if data[:key][:fromMe]

    # Check for media messages and send response directly
    media_type = detect_media_message_type
    if media_type
      send_media_response(user.whatsapp_number, media_type)
      return {
        user: user,
        message_data: data,
        system_message: false,
        media_response_sent: true
      }
    end

    message_text = extract_message_text

    if message_text.present?
      ProcessWhatsappMessageJob.perform_later(
        user.id,
        message_text,
        user.whatsapp_number
      )
    end

    {
      user: user,
      message_data: data,
      system_message: false
    }
  end

  private

  def find_or_create_user
    whatsapp_number = data[:key][:remoteJid]
    User.find_or_create_by(whatsapp_number: whatsapp_number)
  end

  def detect_media_message_type
    message = data[:message]
    return nil unless message.present?

    if is_non_empty_media_type?(message, :imageMessage)
      'image'
    elsif is_non_empty_media_type?(message, :videoMessage)
      'video'
    elsif is_non_empty_media_type?(message, :audioMessage)
      'audio'
    elsif is_non_empty_media_type?(message, :documentMessage)
      'document'
    elsif is_non_empty_media_type?(message, :stickerMessage)
      'sticker'
    end
  end

  def send_media_response(phone_number, media_type)
    response_text = "Thank you for #{media_type ? "sending us this #{media_type}" : "your message"}, unfortunately we can only respond to Text messages at the moment"

    begin
      messages_api = WasenderApi::Messages.new
      messages_api.send_text({
        to: phone_number,
        text: response_text
      })
      Rails.logger.info("Sent media response to #{phone_number} for #{media_type} message")
    rescue => e
      Rails.logger.error("Failed to send media response to #{phone_number}: #{e.message}")
    end
  end

  def extract_message_text
    message = data[:message]
    return nil unless message.present?

    if message[:conversation].present?
      message[:conversation]
    elsif message[:extendedTextMessage].present? && message[:extendedTextMessage][:text].present?
      message[:extendedTextMessage][:text]
    end
  end

  def is_non_empty_media_type?(message_hash, media_type)
    message_hash[media_type].present? && has_media_content?(message_hash[media_type])
  end

  def has_media_content?(media_hash)
    # Check if the media hash has any non-nil values (indicating actual content)
    media_hash.values.any?(&:present?)
  end
end
