class Strava::SyncerJob
  include Sidekiq::Job

  def perform(*args)
    strava_api = StravaApi::StravaApiRequest.new
    
    User.all.each do |user|
      if user.strava_access_token.present?
        if user.strava_expires_at < Time.now
          update_user_metrics(user.strava_access_token)
        else
          response = strava_api.refresh_access_token(user.refresh_token)

          Current.user.strava_access_token = response.access_token
          Current.user.strava_refresh_token = response.refresh_token
          Current.user.strava_expires_at = response.expires_at

          Current.user.save

          update_user_metrics(user.strava_access_token)
        end 
      else
        next
      end
    end
  end

  def update_user_metrics(access_token)
    activities = strava_api.fetch_athlete_activities(access_token)
    user.update_athlete_activities(activities)
  end
end
