class ApplicationController < ActionController::Base
  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_user_logged_in
    return if Current.user

    flash[:alert] = 'You must be logged in to access this section'
    redirect_to sign_in_path
  end
end
