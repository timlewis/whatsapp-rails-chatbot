class MessagesController < ApplicationController
  before_action :set_message, only: [:show]

  def index
    @messages = Message.joins(chat: :user).includes(chat: :user, :tool_calls).order(created_at: :desc)
    @messages = @messages.where(chat_id: params[:chat_id]) if params[:chat_id].present?
    
    @stats = {
      total_messages: @messages.count,
      user_messages: @messages.where(role: 'user').count,
      assistant_messages: @messages.where(role: 'assistant').count,
      system_messages: @messages.where(role: 'system').count,
      total_tokens: @messages.sum('COALESCE(input_tokens, 0) + COALESCE(output_tokens, 0)')
    }
  end

  def show
    @tool_calls = @message.tool_calls.order(:created_at)
  end

  private

  def set_message
    @message = Message.joins(chat: :user).includes(chat: :user, :tool_calls).find(params[:id])
  end
end
