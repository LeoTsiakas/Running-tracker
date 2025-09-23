class Strava::UserSyncJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find(user_id)
    strava_api = StravaApi::StravaApiRequest.new

    if user.strava_expires_at > Time.now
      update_user_metrics(user, user.strava_access_token, strava_api)
    else
      response = strava_api.refresh_access_token(user.strava_refresh_token)

      user.update(
        strava_access_token: response.access_token,
        strava_refresh_token: response.refresh_token,
        strava_expires_at: response.expires_at
      )

      update_user_metrics(user, user.strava_access_token, strava_api)
    end
    puts "Strava activities synced"
  end

  def update_user_metrics(user, access_token, strava_api)
    activities = strava_api.fetch_athlete_activities(access_token)
    user.update_athlete_activities(activities)
  end
end
