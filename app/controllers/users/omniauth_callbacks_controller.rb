module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      user = User.from_omniauth(request.env['omniauth.auth'])

      if user
        sign_in_and_redirect user, event: :authentication
        set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
      else
        redirect_to new_user_session_path,
                    alert: 'We could not sign you in with Google. Please try again or use your email and password.'
      end
    end

    def failure
      redirect_to new_user_session_path, alert: 'Google sign in was cancelled.'
    end
  end
end
