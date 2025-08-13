class ChatsController < ApplicationController
  before_action :set_chat, only: [:show]

  def index
    @chats = Chat.joins(:user).includes(:user, :messages).order(updated_at: :desc)
    @chats = @chats.where(user_id: params[:user_id]) if params[:user_id].present?
    
    @stats = {
      total_chats: @chats.count,
      active_today: @chats.where('updated_at >= ?', 1.day.ago).count,
      total_messages: Message.joins(chat: :user).count,
      unique_users: @chats.joins(:user).distinct.count('users.id')
    }
  end

  def show
    @messages = @chat.messages.order(:created_at)
    @message_stats = {
      total_messages: @messages.count,
      user_messages: @messages.where(role: 'user').count,
      assistant_messages: @messages.where(role: 'assistant').count,
      tool_calls: @chat.tool_calls.count
    }
  end

  private

  def set_chat
    @chat = Chat.joins(:user).includes(:user, :messages, :tool_calls).find(params[:id])
  end
end
