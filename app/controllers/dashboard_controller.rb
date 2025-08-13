class DashboardController < ApplicationController
  def index
    @stats = {
      personas: Persona.count,
      users: User.count,
      chats: Chat.count,
      messages: Message.count,
      tool_calls: ToolCall.count
    }

    # Recent activity
    @recent_chats = Chat.includes(:user).order(updated_at: :desc).limit(5)
    @recent_messages = Message.includes(chat: :user).order(created_at: :desc).limit(10)
    @default_persona = Persona.default.first
  end
end
