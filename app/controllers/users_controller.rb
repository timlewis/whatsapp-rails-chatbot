class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.includes(:chats).order(:whatsapp_number)
    @stats = {
      total_users: @users.count,
      users_with_chats: @users.joins(:chats).distinct.count,
      total_chats: Chat.count,
      total_messages: Message.count
    }
  end

  def show
    @recent_chats = @user.chats.includes(:messages).order(updated_at: :desc).limit(5)
    @message_count = @user.messages.count
    @tool_call_count = @user.tool_calls.count
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: 'User was successfully deleted.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:whatsapp_number)
  end
end
