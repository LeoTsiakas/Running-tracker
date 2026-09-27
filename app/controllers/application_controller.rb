class ApplicationController < ActionController::Base
  include Pagy::Method

  layout :layout_by_resource
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:time_zone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:time_zone])
  end

  def layout_by_resource
    user_signed_in? ? 'application' : 'guest'
  end
end
