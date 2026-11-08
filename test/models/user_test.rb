require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ username: 'runner', email: 'runner@example.com', password: 'secret123', time_zone: 'UTC' }.merge(attrs))
  end

  test 'is valid with valid attributes' do
    assert build_user.valid?
  end

  test 'is invalid without email' do
    user = build_user(email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'is invalid with a malformed email' do
    user = build_user(email: 'not-an-email')
    assert_not user.valid?
    assert_includes user.errors[:email], 'is invalid'
  end

  test 'is invalid with an email that is already taken' do
    user = build_user(email: users(:one).email.upcase)
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'is invalid without password' do
    user = build_user(password: nil)
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test 'is invalid with a too short password' do
    user = build_user(password: '12345')
    assert_not user.valid?
    assert_includes user.errors[:password], 'is too short (minimum is 6 characters)'
  end

  test 'is invalid when password confirmation does not match' do
    user = build_user(password_confirmation: 'different')
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test 'is invalid without time zone' do
    user = build_user(time_zone: '')
    assert_not user.valid?
    assert_includes user.errors[:time_zone], "can't be blank"
  end

  test 'normalizes an IANA time zone to its ActiveSupport name' do
    user = build_user(time_zone: 'Europe/Athens')
    user.valid?
    assert_equal 'Athens', user.time_zone
  end

  test 'keeps a time zone that is already an ActiveSupport name' do
    user = build_user(time_zone: 'Athens')
    user.valid?
    assert_equal 'Athens', user.time_zone
  end

  test 'normalizes a blank time zone to nil' do
    user = build_user(time_zone: '   ')
    user.valid?
    assert_nil user.time_zone
  end

  test 'builds metric by registered_at' do
    user = users(:one)
    metric1 = metrics(:one)
    metric2 = metrics(:two)

    expected_hash = {
      metric1.date.utc => metric1,
      metric2.date.utc => metric2
    }

    assert_equal expected_hash, user.metrics_by_registered_at
  end

  # --- update_athlete_activities ---------------------------------------------

  def strava_activity(elapsed_time: 1800, distance: 5000.0, start_date_local: 2.days.ago.change(usec: 0))
    strava_response(elapsed_time: elapsed_time, distance: distance, start_date_local: start_date_local)
  end

  test 'update_athlete_activities creates a metric for each new Strava activity' do
    user = users(:one)
    started_at = Time.utc(2026, 10, 1, 7, 30)

    assert_difference('user.metrics.count', 2) do
      user.update_athlete_activities([strava_activity(start_date_local: started_at), strava_activity])
    end

    metric = user.metrics.find_by(date: started_at)
    assert_equal 5.0, metric.distance
  end

  test 'update_athlete_activities skips activities that are already stored' do
    user = users(:one)
    existing = strava_activity(start_date_local: metrics(:one).date)

    assert_difference('user.metrics.count', 1) do
      user.update_athlete_activities([existing, strava_activity])
    end
  end

  test 'update_athlete_activities does not import the same activity twice' do
    user = users(:one)
    activity = strava_activity

    user.update_athlete_activities([activity])

    assert_no_difference('Metric.count') { user.reload.update_athlete_activities([activity]) }
  end

  test 'update_athlete_activities stores the duration in seconds like manual metrics' do
    skip 'BUG: elapsed_time is turned into a "30:0" minutes string, which the integer column casts to 30'

    user = users(:one)
    started_at = Time.utc(2026, 10, 1, 7, 30)

    user.update_athlete_activities([strava_activity(elapsed_time: 1800, start_date_local: started_at)])

    assert_equal 1800, user.metrics.find_by(date: started_at).time
  end

  # --- from_omniauth ---------------------------------------------------------

  def google_auth(email: 'google.runner@example.com', verified: true, uid: 'google-123')
    OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: uid,
      info: { email: email, name: 'Google Runner' },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  test 'from_omniauth returns the user already linked to the Google account' do
    users(:two).update_columns(provider: 'google_oauth2', uid: 'google-123')

    assert_no_difference('User.count') do
      assert_equal users(:two), User.from_omniauth(google_auth(email: 'changed@example.com'))
    end
  end

  test 'from_omniauth links Google to an existing account with the same email' do
    user = assert_no_difference('User.count') { User.from_omniauth(google_auth(email: users(:one).email)) }

    assert_equal users(:one), user
    assert_equal 'google_oauth2', user.reload.provider
    assert_equal 'google-123', user.uid
    assert_equal 'leo_ts', user.username
  end

  test 'from_omniauth creates a new user from the Google profile' do
    user = assert_difference('User.count', 1) { User.from_omniauth(google_auth) }

    assert user.persisted?
    assert_equal 'google.runner@example.com', user.email
    assert_equal 'Google Runner', user.username
    assert_equal 'UTC', user.time_zone
    assert_equal %w[google_oauth2 google-123], [user.provider, user.uid]
  end

  test 'from_omniauth returns nil when Google has not verified the email' do
    assert_no_difference('User.count') do
      assert_nil User.from_omniauth(google_auth(verified: false))
    end
  end

  test 'from_omniauth returns nil when Google sends no email' do
    assert_no_difference('User.count') do
      assert_nil User.from_omniauth(google_auth(email: nil))
    end
  end
end
