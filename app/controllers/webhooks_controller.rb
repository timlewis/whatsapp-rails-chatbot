class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /webhook
  def receive
    begin
      unless valid_signature?(request)
        render json: { error: 'Invalid signature' }, status: :unauthorized and return
      end
    rescue RuntimeError => e
      render json: { error: "Webhook secret unavailable: #{e.message}" }, status: :internal_server_error and return
    end

    payload = webhook_params
    event = payload['event']

    case event
    when 'messages.upsert'
      handle_message_upsert(payload['data'])
    end

    render json: { received: true }, status: :ok
  end

  private

  def webhook_params
    params.permit(:event, :timestamp, data: {})
  end

  def valid_signature?(request)
    signature = request.headers['X-Webhook-Signature']
    webhook_secret = WasenderApi.webhook_secret
    signature.present? && webhook_secret.present? && ActiveSupport::SecurityUtils.secure_compare(signature, webhook_secret)
  end

  def handle_message_upsert(data)
    Rails.logger.info("New message received: #{data['key']['id']}")
    # Add message processing logic here
  end
end
