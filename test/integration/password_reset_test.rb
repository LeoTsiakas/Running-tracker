require 'test_helper'

# Regression test for #30: requesting a password reset must send an email from
# the app's sender, and the link in it must let the user set a new password.
class PasswordResetTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = 'newpass123'.freeze

  test 'requesting a reset emails a link that sets a new password' do
    user = users(:one)

    mails = capture_emails do
      post user_password_path, params: { user: { email: user.email } }
    end

    assert_redirected_to new_user_session_path
    assert_equal 1, mails.size

    mail = mails.first
    assert_equal [user.email], mail.to
    assert_equal ['no-reply@running-tracker.local'], mail.from

    token = mail.body.encoded[/reset_password_token=([^"&\s]+)/, 1]
    assert token, 'expected the email to contain a reset password link'

    put user_password_path, params: {
      user: { reset_password_token: token, password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD }
    }

    assert user.reload.valid_password?(NEW_PASSWORD)
  end

  test 'an unknown email sends nothing' do
    mails = capture_emails do
      post user_password_path, params: { user: { email: 'nobody@example.com' } }
    end

    assert_empty mails
  end
end
