class DashboardController < ApplicationController
  def index
    @stats = {
      personas: Persona.count,
      users: User.count,
      chats: Chat.count,
      messages: Message.count,
      tool_calls: ToolCall.count,
      admin_users: AdminUser.count
    }

    # Recent activity - only include chats that have users and messages
    # Order by the most recent message timestamp for each chat
    @recent_chats = Chat.joins(:user, :messages)
                       .includes(:user, :messages)
                       .group('chats.id')
                       .order('MAX(messages.created_at) DESC')
                       .limit(5)
    @recent_messages = Message.joins(chat: :user).includes(chat: :user).order(created_at: :desc).limit(10)
    @default_persona = Persona.default.first

    # Get WhatsApp session status
    @whatsapp_status = get_whatsapp_status
  end

  private

  def get_whatsapp_status
    session = WasenderApi::Session.new
    session_id = WasenderApi.get_session_id(session.config.phone_number)
    response = session.details(session_id)
    if response.success?
      [ response.data[:status], response.data[:status] ]
    else
      [ 'error', response.body[:message] || 'unknown error' ]
    end
  rescue StandardError => e
    Rails.logger.error("Failed to get WhatsApp session status: #{e.message}")
    [ 'unavailable', e&.message || 'unknown error' ]
  end
end
