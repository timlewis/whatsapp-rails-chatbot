module WasenderApi
  WasenderConfig = Struct.new(:personal_access_token, :base_url, :phone_number, keyword_init: true)
  DEFAULT_CONFIG = WasenderConfig.new(
    personal_access_token: ENV.fetch('WASENDER_PERSONAL_ACCESS_TOKEN'),
    base_url: ENV.fetch('WASENDER_BASE_URL'),
    phone_number: ENV.fetch('WASENDER_PHONE_NUMBER')
  ).freeze

  WEBHOOK_EVENTS = %w[
    contacts.update
    contacts.upsert
    group-participants.update
    groups.update
    chats.update
    message.sent
    groups.upsert
    chats.upsert
    chats.delete
    session.status
    qrcode.updated
    messages.upsert
    messages.received
    messages.status.update
    messages.deleted
    messages.receipt.update
    messages.reaction
    poll.results
  ].freeze

  module_function

  def get_session_id(phone_number)
    return session_id_hash[phone_number] if session_id_hash && session_id_hash[phone_number]

    response = WasenderApi::Session.new.list
    if response.success?
      session = response.data.detect { |s| s[:phone_number] == phone_number && s[:status] == 'connected' }
      if session
        self.session_id_hash ||= {}
        self.session_id_hash[phone_number] = session[:id]
        session[:id]
      else
        raise "No session found for phone number: #{phone_number}"
      end
    else
      raise "Failed to retrieve sessions: #{response.body[:message]}"
    end
  end

  def session_api_token(config = nil)
    config ||= DEFAULT_CONFIG
    session_id = get_session_id(config.phone_number)
    return session_hash[session_id].first if session_hash && session_hash[session_id]

    response = WasenderApi::Session.new.details(session_id)
    if response.success?
      self.session_hash ||= {}
      self.session_hash[session_id] = [ response.data[:api_key], response.data[:webhook_secret] ]
      response.data[:api_key]
    else
      raise "Failed to retrieve session API token: #{response.body[:message]}"
    end
  end

  def webhook_secret(config = nil)
    config ||= DEFAULT_CONFIG
    session_id = get_session_id(config.phone_number)
    return session_hash[session_id].last if session_hash && session_hash[session_id]

    response = WasenderApi::Session.new.details(session_id)
    if response.success?
      self.session_hash ||= {}
      self.session_hash[session_id] = [ response.data[:api_key], response.data[:webhook_secret] ]
      response.data[:webhook_secret]
    else
      raise "Failed to retrieve session webhook secret: #{response.body[:message]}"
    end
  end

  # Split a long message into smaller chunks for better WhatsApp readability.
  def split_message(text, max_lines: 3, max_chars_per_line: 100)
    text = text.to_s
    return [ '' ] if text.empty?

    # Split by newlines (including escaped \n from LLM responses)
    lines = text.split(/\\n|\n/).flat_map do |paragraph|
      if paragraph.length > max_chars_per_line
        # Split long paragraphs by words, respecting word boundaries
        split_paragraph_by_words(paragraph, max_chars_per_line)
      else
        paragraph
      end
    end

    # Group lines into chunks of max_lines each
    lines.each_slice(max_lines).map { |chunk| chunk.join("\n") }.reject(&:blank?)
  end

  def split_paragraph_by_words(paragraph, max_chars_per_line)
    words = paragraph.split
    lines = []
    current_line = []

    words.each do |word|
      # Check if adding this word would exceed the line limit
      test_line_length = current_line.join(' ').length + word.length + (current_line.empty? ? 0 : 1)

      if test_line_length <= max_chars_per_line
        current_line << word
      else
        # Finish current line and start a new one
        lines << current_line.join(' ') if current_line.any?
        current_line = [ word ]
      end
    end

    # Don't forget the last line
    lines << current_line.join(' ') if current_line.any?
    lines
  end

  # session_hash contains a hash of session_id => [api_token, webhook_secret]
  # session_id_hash contains a hash of phone_number => session_id
  thread_mattr_accessor :session_hash, :session_id_hash, instance_accessor: false

  class Connection
    class << self
      def create(config, bearer_token)
        Faraday.new(
          url: URI.parse(config.base_url),
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{bearer_token}"
          }
        )
      end
    end
  end

  class Request
    def initialize(config, bearer_token)
      @config = config
      @bearer_token = bearer_token
    end

    def get(path, extra_headers = nil, **options)
      request(:get, path, options, extra_headers)
    end

    def post(path, extra_headers = nil, **options)
      request(:post, path, options, extra_headers)
    end

    def put(path, extra_headers = nil, **options)
      request(:put, path, options, extra_headers)
    end

    def delete(path, extra_headers = nil, **options)
      request(:delete, path, options, extra_headers)
    end

    private

    attr_reader :config, :bearer_token

    def request(method, path, payload, extra_headers)
      payload = payload.to_json if %i[post put].include?(method.to_sym)
      full_response = WasenderApi::Connection.create(config, bearer_token).send(method, path, payload, extra_headers)
      Response.new(full_response)
    end
  end

  class Response
    def initialize(full_response)
      @status_code = full_response.status
      @full_response = full_response
    end

    attr_reader :status_code, :full_response

    def success?
      full_response.success?
    end

    def failure?
      !success?
    end

    def data
      return {} unless success?
      data = body[:data]
      return {} if data.blank?

      data
    end

    def body
      return {} if full_response.body.blank?

      JSON.parse(full_response.body).with_indifferent_access
    end
  end

  class Base
    def initialize(config = nil)
      @config = config || DEFAULT_CONFIG
    end
    attr_reader :config

    private

    def validate_payload(payload, required_keys: [])
      raise ArgumentError, 'payload must be a Hash' unless payload.is_a?(Hash)
      required_keys.each do |key|
        value = payload.fetch(key) { raise ArgumentError, "payload must include :#{key} key" }
        if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          raise ArgumentError, "payload :#{key} must be true or false" unless [ true, false ].include?(value)
        else
          raise ArgumentError, "payload :#{key} must be present" unless value.present?
        end
      end
    end
  end

  class Session < Base
    def initialize(config = nil)
      super
      @request = Request.new(@config, @config.personal_access_token)
    end

    attr_reader :request

    def list
      # https://wasenderapi.com/api-docs/sessions/get-all-whatsapp-sessions
      request.get('whatsapp-sessions')
    end

    def details(session_id)
      # https://wasenderapi.com/api-docs/sessions/get-whatsapp-session-details
      # session_id: integer, required
      request.get("whatsapp-sessions/#{session_id}")
    end

    def update(session_id, payload)
      # https://wasenderapi.com/api-docs/sessions/update-whatsapp-session
      # session_id: integer, required
      # payload: hash with the following optional keys and values, add key/value pairs as needed
      # optional: name: string, phone_number: string, account_protection: boolean, log_messages: boolean
      # webhook_url: string, webhook_enabled: boolean, webhook_events: array
      request.put("whatsapp-sessions/#{session_id}", **payload)
    end

    def create(payload)
      # https://wasenderapi.com/api-docs/sessions/create-whatsapp-session
      # payload: hash with the following
      # Required: name: string, phone_number: string, account_protection: boolean, log_messages: boolean
      # Optional: webhook_url: string, webhook_enabled: boolean, webhook_events: array
      validate_payload(payload, required_keys: %i[name phone_number account_protection log_messages])
      request.post('whatsapp-sessions', **payload)
    end

    def connect(session_id)
      # https://wasenderapi.com/api-docs/sessions/connect-whatsapp-session
      # session_id: integer, required
      # returns either status of CONNECTED or NEED_SCAN in data: status
      # If status is NEED_SCAN, QR Code string will be returned in data: qrCode, use QR code library to display it
      request.post("whatsapp-sessions/#{session_id}/connect")
    end

    def qrcode(session_id)
      # https://wasenderapi.com/api-docs/sessions/get-whatsapp-session-qr-code
      # session_id: integer, required
      # returns QR code string, use QR code library to display it
      # NB!! before calling this method, you must call connect method
      request.get("whatsapp-sessions/#{session_id}/qrcode")
    end
  end

  class Messages < Base
    def initialize(config = nil)
      super
      @request = Request.new(@config, WasenderApi.session_api_token(@config))
    end

    attr_reader :request

    def send_text(payload)
      # https://wasenderapi.com/api-docs/messages/send-text-message
      # required: to: string (phone number in E.164 format), text: string
      validate_payload(payload, required_keys: %i[to text])
      request.post('send-message', **payload)
    end

    def send_image(payload)
      # https://wasenderapi.com/api-docs/messages/send-image-message
      # required: to: string (phone number in E.164 format), imageUrl: string (image URL)
      # optional: text: string for caption
      validate_payload(payload, required_keys: %i[to imageUrl])
      request.post('send-message', **payload)
    end

    def send_video(payload)
      # https://wasenderapi.com/api-docs/messages/send-video-message
      # required: to: string (phone number in E.164 format), video: videoUrl (video URL)
      # optional: text: string for caption
      validate_payload(payload, required_keys: %i[to videoUrl])
      request.post('send-message', **payload)
    end

    def send_document(payload)
      # https://wasenderapi.com/api-docs/messages/send-document-message
      # required: to: string (phone number in E.164 format), documentUrl: string (document URL)
      # optional: text: string for caption, fileName: string The file name of the document. If not provided, document.{extension} will be used.
      validate_payload(payload, required_keys: %i[to documentUrl])
      request.post('send-message', **payload)
    end

    def send_audio(payload)
      # https://wasenderapi.com/api-docs/messages/send-audio-message
      # required: to: string (phone number in E.164 format), audioUrl: string (audio URL)
      # optional: text: string for caption
      validate_payload(payload, required_keys: %i[to audioUrl])
      request.post('send-message', **payload)
    end

    def send_sticker(payload)
      # https://wasenderapi.com/api-docs/messages/send-sticker-message
      # required: to: string (phone number in E.164 format), stickerUrl: string (sticker URL)
      # optional: text: string for caption
      validate_payload(payload, required_keys: %i[to stickerUrl])
      request.post('send-message', **payload)
    end

    def send_contact(payload)
      # https://wasenderapi.com/api-docs/messages/send-contact-card
      # required: to: string (phone number in E.164 format), contact: hash with contact details
      # contact: hash with the following keys
      # name: string, phone: string (phone number in E.164 format), email
      validate_payload(payload, required_keys: %i[to contact])
      validate_payload(payload[:contact], required_keys: %i[name phone])
      request.post('send-message', **payload)
    end

    def send_location(payload)
      # https://wasenderapi.com/api-docs/messages/send-location-message
      # required: to: string (phone number in E.164 format), location: hash with location details
      # location: hash with the following keys
      # latitude: float, longitude: float, name: string, address: string
      validate_payload(payload, required_keys: %i[to location])
      validate_payload(payload[:location], required_keys: %i[latitude longitude name address])
      request.post('send-message', **payload)
    end
  end

  class Groups < Base
    def initialize(config = nil)
      super(config)
      @request = Request.new(@config, WasenderApi.session_api_token(@config))
    end

    attr_reader :request

    # Get all groups the connected account is a member of
    # https://wasenderapi.com/api-docs/groups/get-all-groups
    def list
      request.get('groups')
    end

    # Send a message to a group: use the Messages class to send messages to a group. but instead of a phone number, use the Group ID.
    # Send a message directly to a WhatsApp group using its unique Group ID (e.g., `123456789-987654321@g.us`).
    # Use the `/api/groups` endpoint to find the IDs of the groups you are in.
    # The parameters are the same as sending a regular message, but the `to` field must contain the Group ID.

    # Get metadata for a specific group
    # https://wasenderapi.com/api-docs/groups/get-group-metadata
    # group_jid: The JID (Jabber ID) of the group in the format 123456789-987654321@g.us.
    def metadata(group_jid)
      request.get("groups/#{group_jid}/metadata")
    end

    # Get participants for a specific group
    # https://wasenderapi.com/api-docs/groups/get-group-participants
    # group_jid: The JID (Jabber ID) of the group in the format 123456789-987654321@g.us.
    def participants(group_jid)
      request.get("groups/#{group_jid}/participants")
    end

    # Add participants to a group
    # https://wasenderapi.com/api-docs/groups/add-group-participants
    # participants: array of phone numbers (E.164 format)
    def add_participants(group_jid, participants)
      raise ArgumentError, 'participants must be an array' unless participants.is_a?(Array)
      request.post("groups/#{group_jid}/participants/add", participants: participants)
    end

    # Remove participants from a group
    # https://wasenderapi.com/api-docs/groups/remove-group-participants
    # participants: array of phone numbers (E.164 format)
    def remove_participants(group_jid, participants)
      raise ArgumentError, 'participants must be an array' unless participants.is_a?(Array)
      request.post("groups/#{group_jid}/participants/remove", participants: participants)
    end

    # Update group settings (subject, description, announce, restrict)
    # https://wasenderapi.com/api-docs/groups/update-group-settings
    # settings: hash with any of :subject(string), :description(string), :announce(bool), :restrict(bool)
    def update_settings(group_jid, settings)
      raise ArgumentError, 'settings must be a hash' unless settings.is_a?(Hash)
      request.put("groups/#{group_jid}/settings", **settings)
    end
  end

  class Contacts < Base
    def initialize(config = nil)
      super
      @request = Request.new(@config, WasenderApi.session_api_token(@config))
    end

    attr_reader :request

    # Get all contacts synced with the WhatsApp session
    # https://wasenderapi.com/api-docs/contacts/get-all-contacts
    def list
      request.get('contacts')
    end

    # Get detailed info for a specific contact
    # https://wasenderapi.com/api-docs/contacts/get-contact-info
    # contact_phone_number: The JID (Jabber ID) of the contact in E.164 format (international phone number)
    def info(contact_phone_number)
      request.get("contacts/#{contact_phone_number}")
    end

    # Get profile picture URL for a specific contact
    # https://wasenderapi.com/api-docs/contacts/get-contact-profile-picture
    # contact_phone_number: The JID (Jabber ID) of the contact in E.164 format (international phone number)
    def picture(contact_phone_number)
      request.get("contacts/#{contact_phone_number}/picture")
    end

    # Block a specific contact
    # https://wasenderapi.com/api-docs/contacts/block-contact
    # contact_phone_number: The JID (Jabber ID) of the contact in E.164 format (international phone number)
    def block(contact_phone_number)
      request.post("contacts/#{contact_phone_number}/block")
    end

    # Unblock a specific contact
    # https://wasenderapi.com/api-docs/contacts/unblock-contact
    # contact_phone_number: The JID (Jabber ID) of the contact in E.164 format (international phone number)
    def unblock(contact_phone_number)
      request.post("contacts/#{contact_phone_number}/unblock")
    end
  end
end
