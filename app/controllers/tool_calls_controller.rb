class ToolCallsController < ApplicationController
  before_action :set_tool_call, only: [:show]

  def index
    @tool_calls = ToolCall.joins(message: { chat: :user }).includes(message: { chat: :user }).order(created_at: :desc)
    @tool_calls = @tool_calls.where(message_id: params[:message_id]) if params[:message_id].present?
    
    @stats = {
      total_tool_calls: @tool_calls.count,
      unique_tools: @tool_calls.distinct.count(:name),
      recent_calls: @tool_calls.where('created_at >= ?', 1.day.ago).count,
      most_used_tool: @tool_calls.group(:name).count.max_by { |k, v| v }&.first
    }
    
    @tool_usage = @tool_calls.group(:name).count.sort_by { |k, v| -v }.first(10)
  end

  def show
  end

  private

  def set_tool_call
    @tool_call = ToolCall.joins(message: { chat: :user }).includes(message: { chat: :user }).find(params[:id])
  end
end
