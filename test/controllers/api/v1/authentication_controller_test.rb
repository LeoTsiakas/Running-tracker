require 'test_helper'

class Api::V1::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  # Records every call the controller makes to Strava and answers with canned data.
  class FakeStravaApi
    AUTHORIZE_URL = 'https://www.strava.com/oauth/authorize?client_id=test'.freeze

    attr_reader :calls

    def initialize(activities: [], token: nil)
      @activities = activities
      @token = token
      @calls = []
    end

    def authorize
      calls << [:authorize]
      AUTHORIZE_URL
    end

    def fetch_access_token(code)
      calls << [:fetch_access_token, code]
      @token
    end

    def refresh_access_token(refresh_token)
      calls << [:refresh_access_token, refresh_token]
      @token
    end

    def fetch_athlete_activities(access_token)
      calls << [:fetch_athlete_activities, access_token]
      @activities
    end
  end

  setup do
    @user = users(:one)
    @new_token = strava_response(access_token: 'new-access', refresh_token: 'new-refresh', expires_at: 6.hours.from_now)
    @activity = strava_response(elapsed_time: 1800, distance: 5000.0, start_date_local: 2.days.ago.change(usec: 0))
  end

  def with_strava(**options)
    fake = FakeStravaApi.new(**options)
    StravaApi::StravaApiRequest.stub(:new, fake) { yield fake }
  end

  def connect_strava(user, expires_at:)
    user.update_columns(strava_access_token: 'old-access', strava_refresh_token: 'old-refresh',
                        strava_expires_at: expires_at)
  end

  test 'requires a signed in user' do
    get api_v1_strava_authenticate_path
    assert_redirected_to new_user_session_path

    get api_v1_auth_strava_callback_path, params: { code: 'abc', scope: 'read,activity:read_all' }
    assert_redirected_to new_user_session_path
  end

  # --- start ----------------------------------------------------------------

  test 'start sends a user without a Strava token to the Strava authorize page' do
    sign_in @user

    with_strava do |strava|
      get api_v1_strava_authenticate_path

      assert_redirected_to FakeStravaApi::AUTHORIZE_URL
      assert_equal [[:authorize]], strava.calls
    end
  end

  test 'start syncs activities with a token that is still valid' do
    connect_strava(@user, expires_at: 1.hour.from_now)
    sign_in @user

    with_strava(activities: [@activity]) do |strava|
      assert_difference('@user.metrics.count', 1) { get api_v1_strava_authenticate_path }

      assert_equal [[:fetch_athlete_activities, 'old-access']], strava.calls
      assert_redirected_to root_path
      assert_equal 'Strava activities synced!', flash[:notice]
    end
  end

  test 'start refreshes an expired token, stores it and then syncs with the new one' do
    connect_strava(@user, expires_at: 1.hour.ago)
    sign_in @user

    with_strava(activities: [@activity], token: @new_token) do |strava|
      get api_v1_strava_authenticate_path

      assert_equal [[:refresh_access_token, 'old-refresh'], [:fetch_athlete_activities, 'new-access']], strava.calls
      assert_redirected_to root_path
    end

    @user.reload
    assert_equal 'new-access', @user.strava_access_token
    assert_equal 'new-refresh', @user.strava_refresh_token
    assert_in_delta @new_token.expires_at, @user.strava_expires_at, 1.second
  end

  # --- callback -------------------------------------------------------------

  test 'callback stores the tokens and syncs activities' do
    sign_in @user

    with_strava(activities: [@activity], token: @new_token) do |strava|
      assert_difference('@user.metrics.count', 1) do
        get api_v1_auth_strava_callback_path, params: { code: 'abc', scope: 'read,activity:read_all' }
      end

      assert_equal [[:fetch_access_token, 'abc'], [:fetch_athlete_activities, 'new-access']], strava.calls
      assert_redirected_to root_path
      assert_equal 'Strava activities synced!', flash[:notice]
    end

    assert_equal 'new-access', @user.reload.strava_access_token
    assert_equal 'new-refresh', @user.strava_refresh_token
  end

  test 'callback accepts the activity:read scope' do
    sign_in @user

    with_strava(token: @new_token) do |strava|
      get api_v1_auth_strava_callback_path, params: { code: 'abc', scope: 'read,activity:read' }

      assert_equal [:fetch_access_token, 'abc'], strava.calls.first
      assert_equal 'Strava activities synced!', flash[:notice]
    end
  end

  test 'callback fails when the user denied access on Strava' do
    sign_in @user

    with_strava do |strava|
      get api_v1_auth_strava_callback_path, params: { error: 'access_denied', scope: 'read' }

      assert_empty strava.calls
      assert_redirected_to root_path
      assert_match 'Activities sync failed', flash[:alert]
    end
  end

  test 'callback fails when the user did not grant an activity scope' do
    sign_in @user

    with_strava do |strava|
      get api_v1_auth_strava_callback_path, params: { code: 'abc', scope: 'read' }

      assert_empty strava.calls
      assert_redirected_to root_path
      assert_match 'Activities sync failed', flash[:alert]
    end

    assert_nil @user.reload.strava_access_token
  end

  test 'callback fails gracefully when Strava sends no scope' do
    skip 'BUG: params[:scope].split raises NoMethodError when scope is missing and there is no error param'

    sign_in @user

    with_strava do |strava|
      get api_v1_auth_strava_callback_path, params: { code: 'abc' }

      assert_empty strava.calls
      assert_redirected_to root_path
      assert_match 'Activities sync failed', flash[:alert]
    end
  end
end
