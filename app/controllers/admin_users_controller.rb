class AdminUsersController < ApplicationController
  before_action :set_admin_user, only: [ :destroy ]

  def index
    @admin_users = AdminUser.includes(:sessions).order(:email_address)
  end

  def new
    @admin_user = AdminUser.new
  end

  def create
    @admin_user = AdminUser.new(admin_user_params)

    if @admin_user.save
      redirect_to admin_users_path, notice: 'Admin user was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @admin_user == Current.admin_user
      redirect_to admin_users_path, alert: 'You cannot delete your own account.'
    else
      @admin_user.destroy
      redirect_to admin_users_path, notice: 'Admin user was successfully deleted.'
    end
  end

  private

  def set_admin_user
    @admin_user = AdminUser.find(params[:id])
  end

  def admin_user_params
    params.require(:admin_user).permit(:email_address, :password, :password_confirmation)
  end
end
