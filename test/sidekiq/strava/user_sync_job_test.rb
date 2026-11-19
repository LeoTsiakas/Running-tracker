require 'test_helper'

class Strava::UserSyncJobTest < ActiveSupport::TestCase
  # Records every call the job makes to Strava and answers with canned data.
  class FakeStravaApi
    attr_reader :calls

    def initialize(activities: [], token: nil)
      @activities = activities
      @token = token
      @calls = []
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
    @activity = strava_response(elapsed_time: 1800, distance: 5000.0, start_date_local: 2.days.ago.change(usec: 0))
  end

  def perform_with(fake)
    StravaApi::StravaApiRequest.stub(:new, fake) do
      capture_io { Strava::UserSyncJob.new.perform(@user.id) }
    end
  end

  def connect_strava(expires_at:)
    @user.update_columns(strava_access_token: 'old-access', strava_refresh_token: 'old-refresh',
                         strava_expires_at: expires_at)
  end

  test 'syncs activities with a token that is still valid' do
    connect_strava(expires_at: 1.hour.from_now)
    fake = FakeStravaApi.new(activities: [@activity])

    assert_difference('@user.metrics.count', 1) { perform_with(fake) }

    assert_equal [[:fetch_athlete_activities, 'old-access']], fake.calls
  end

  test 'refreshes an expired token, stores it and syncs with the new one' do
    connect_strava(expires_at: 1.hour.ago)
    new_token = strava_response(access_token: 'new-access', refresh_token: 'new-refresh',
                                expires_at: 6.hours.from_now)
    fake = FakeStravaApi.new(activities: [@activity], token: new_token)

    assert_difference('@user.metrics.count', 1) { perform_with(fake) }

    assert_equal [[:refresh_access_token, 'old-refresh'], [:fetch_athlete_activities, 'new-access']], fake.calls
    @user.reload
    assert_equal 'new-access', @user.strava_access_token
    assert_equal 'new-refresh', @user.strava_refresh_token
    assert_in_delta new_token.expires_at, @user.strava_expires_at, 1.second
  end

  test 'raises when the user no longer exists' do
    assert_raises(ActiveRecord::RecordNotFound) { Strava::UserSyncJob.new.perform(0) }
  end
end
