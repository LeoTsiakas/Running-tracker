class RegistrationsController < ApplicationController
  before_action :set_current_user
  before_action :require_user_logged_in, only: %i[edit update]
  def new
    @user = User.new
  end

  def create
    @user = User.new(users_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'Successfully created account'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find_by(id: Current.user.id)
  end

  def update
    @user = User.find_by(id: Current.user.id)

    if @user.update(users_params)
      redirect_to root_path, notice: 'Successfully updated account'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def users_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
