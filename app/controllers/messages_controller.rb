class MessagesController < ApplicationController
  before_action :set_message, only: [:show]

  def index
    @messages = Message.joins(chat: :user).includes(:tool_calls, chat: :user)
    @messages = @messages.order('messages.created_at DESC')
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
    @tool_calls = @message.tool_calls.order('tool_calls.created_at ASC')
  end

  private

  def set_message
    @message = Message.joins(chat: :user).includes(:tool_calls, chat: :user).find(params[:id])
  end
end