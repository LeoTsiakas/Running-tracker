require 'test_helper'

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  def mock_google(email:, verified: true, uid: 'google-123')
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: uid,
      info: { email: email, name: 'Google Runner' },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  test 'signs in a new Google user and creates the account' do
    mock_google(email: 'new.runner@example.com')

    assert_difference('User.count', 1) do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to root_path
    assert_match 'Google', flash[:notice]
  end

  test 'signs in a user who already linked Google' do
    users(:one).update_columns(provider: 'google_oauth2', uid: 'google-123')
    mock_google(email: users(:one).email)

    assert_no_difference('User.count') do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to root_path
  end

  test 'does not sign in when Google has not verified the email' do
    mock_google(email: 'unverified@example.com', verified: false)

    assert_no_difference('User.count') do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to new_user_session_path
    assert_match 'We could not sign you in with Google', flash[:alert]

    get root_path
    assert_redirected_to new_user_session_path
  end

  test 'redirects to sign in when the Google login fails or is cancelled' do
    OmniAuth.config.mock_auth[:google_oauth2] = :access_denied

    silence_omniauth_logger { get user_google_oauth2_omniauth_callback_path }

    assert_redirected_to new_user_session_path
    assert_equal 'Google sign in was cancelled.', flash[:alert]
  end

  private

  def silence_omniauth_logger
    original = OmniAuth.config.logger
    OmniAuth.config.logger = Logger.new(IO::NULL)
    yield
  ensure
    OmniAuth.config.logger = original
  end
end
