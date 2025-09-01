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
  end
end
