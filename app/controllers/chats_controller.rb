class ChatsController < ApplicationController
  before_action :set_chat, only: [ :show ]

  def index
    @chats = Chat.joins(:user).includes(:user, :messages).order('chats.updated_at DESC')
    @chats = @chats.where(user_id: params[:user_id]) if params[:user_id].present?

    @stats = {
      total_chats: @chats.count,
      active_today: @chats.where('chats.updated_at >= ?', 1.day.ago).count,
      total_messages: Message.joins(chat: :user).count,
      unique_users: @chats.joins(:user).distinct.count('users.id')
    }
  end

  def show
    @messages = @chat.messages.includes(:tool_calls).order(:created_at)
    @stats = {
      user_messages: @messages.where(role: 'user').count,
      assistant_messages: @messages.where(role: 'assistant').count,
      tool_calls: ToolCall.joins(:message).where(messages: { chat_id: @chat.id }).count,
      total_tokens: @messages.sum('COALESCE(input_tokens, 0) + COALESCE(output_tokens, 0)')
    }
  end

  private

  def set_chat
    @chat = Chat.joins(:user).includes(:user, :messages).find(params[:id])
  end
end
