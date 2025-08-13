class WebhooksController < ApplicationController
  allow_unauthenticated_access
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
    when 'messages.received'
      handle_message_received(payload['data'])
    else
      Rails.logger.warn("Unhandled webhook event: #{event}")
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

  def handle_message_received(data)
    interaction = ProcessWebhook.run(
      event: 'messages.received',
      data: data
    )

    if interaction.valid?
      user = interaction.result[:user]
      Rails.logger.info("Processed webhook event 'messages.received' for user #{user.id}")
    else
      Rails.logger.error("Failed to process webhook: #{interaction.errors.full_messages}")
    end
  end
end
