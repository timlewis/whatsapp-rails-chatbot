class PasswordsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create edit update ]
  before_action :set_admin_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if admin_user = AdminUser.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(admin_user).deliver_later
    end

    redirect_to new_session_path, notice: 'Password reset instructions sent (if user with that email address exists).'
  end

  def edit
  end

  def update
    if @admin_user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: 'Password has been reset.'
    else
      redirect_to edit_password_path(params[:token]), alert: 'Passwords did not match.'
    end
  end

  # Authenticated user password change actions
  def edit_current
    @admin_user = Current.admin_user
  end

  def update_current
    @admin_user = Current.admin_user

    if @admin_user.update(params.permit(:password, :password_confirmation))
      redirect_to root_path, notice: 'Password updated successfully.'
    else
      render :edit_current, status: :unprocessable_content
    end
  end

  private
    def set_admin_user_by_token
      @admin_user = AdminUser.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: 'Password reset link is invalid or has expired.'
    end
end
