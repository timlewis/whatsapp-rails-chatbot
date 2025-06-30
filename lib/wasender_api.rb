module WasenderApi
  WasenderConfig = Struct.new(:personal_access_token, :base_url, keyword_init: true)
  DEFAULT_CONFIG = WasenderConfig.new(
    personal_access_token: ENV.fetch('WASENDER_PERSONAL_ACCESS_TOKEN'),
    base_url: ENV.fetch('WASENDER_BASE_URL')
  ).freeze

  module_function

  def session_api_token(session_id)
    return session_hash[session_id].first if session_hash && session_hash[session_id]

    response = WasenderApi::Session.new.details(session_id)
    if response.success?
      self.session_hash = { session_id => [ response.body[:data][:api_token], response.body[:data][:webhook_secret] ] }
      response.body[:data][:api_key]
    else
      raise "Failed to retrieve session API token: #{response.body[:error]}"
    end
  end

  def webhook_secret(session_id)
    return session_hash[session_id].last if session_hash && session_hash[session_id]

    response = WasenderApi::Session.new.details(session_id)
    if response.success?
      self.session_hash = { session_id => [ response.body[:data][:api_token], response.body[:data][:webhook_secret] ] }
      response.body[:data][:webhook_secret]
    else
      raise "Failed to retrieve session webhook secret: #{response.body[:error]}"
    end
  end

  # session_hash contains a hash of session_id => [api_token, webhook_secret]
  thread_mattr_accessor :session_hash, instance_accessor: false

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

    def body
      return {} if full_response.body.blank?

      JSON.parse(full_response.body).with_indifferent_access
    end
  end

  class Base
    def initialize(*args)
      config = args.first
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
    def initialize(config = nil, session_id)
      super
      @session_id = session_id
      @request = Request.new(@config, WasenderApi.session_api_token(@session_id))
    end

    attr_reader :request, :session_id

    def send_text(payload)
      # https://wasenderapi.com/api-docs/messages/send-text-message
      # required: to: string (phone number in E.164 format), text: string
      # optional: text: string for caption
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
end
