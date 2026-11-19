require 'test_helper'

# Devise's own flows are tested by Devise. These cover only what the app adds on
# top: the permitted time_zone param and the layout switch.
class AuthenticationTest < ActionDispatch::IntegrationTest
  PASSWORD = 'secret123'.freeze

  test 'sign up stores the browser time zone' do
    assert_difference('User.count', 1) do
      post user_registration_path, params: {
        user: { email: 'new@example.com', password: PASSWORD, password_confirmation: PASSWORD,
                time_zone: 'Europe/Athens' }
      }
    end

    assert_equal 'Athens', User.find_by(email: 'new@example.com').time_zone
  end

  test 'profile update stores the new time zone' do
    user = User.create!(email: 'runner@example.com', password: PASSWORD, time_zone: 'UTC')
    sign_in user

    put user_registration_path, params: { user: { time_zone: 'America/New_York', current_password: PASSWORD } }

    assert_redirected_to root_path
    assert_equal 'Eastern Time (US & Canada)', user.reload.time_zone
  end

  test 'guests get the guest layout without the app header' do
    get new_user_session_path

    assert_response :success
    assert_select 'a', text: 'Fetch Strava data', count: 0
  end

  test 'signed in users get the application layout with the app header' do
    sign_in users(:one)

    get new_metric_path

    assert_select 'a', text: 'Fetch Strava data'
    assert_select 'button', text: 'Log out'
  end
end
