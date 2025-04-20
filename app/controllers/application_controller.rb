class ApplicationController < ActionController::Base
  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
