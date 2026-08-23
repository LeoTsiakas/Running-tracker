class Api::V1::AuthenticationController < ApplicationController
  before_action :authenticate_user!

  def start
    if current_user.strava_access_token.present?
      if current_user.strava_expires_at > Time.now
        athlete_activities = strava_api.fetch_athlete_activities(current_user.strava_access_token)
        current_user.update_athlete_activities(athlete_activities)

        redirect_to root_path, notice: 'Strava activities synced!'
      else
        response = strava_api.refresh_access_token(current_user.strava_refresh_token)

        update_user_tokens(response)

        start
      end
    else
      redirect_to strava_api.authorize, allow_other_host: true
    end
  end

  def callback
    if params[:error].present? || (["activity:read", "activity:read_all"]&params[:scope].split(",")).empty?
      redirect_to root_path, alert: 'Activities sync failed. Please make sure you authorized our app to access
                                     your Strava data.'
      return
    end

    response = strava_api.fetch_access_token(params[:code])

    update_user_tokens(response)
    athlete_activities = strava_api.fetch_athlete_activities(current_user.strava_access_token)
    current_user.update_athlete_activities(athlete_activities)

    redirect_to root_path, notice: 'Strava activities synced!'
  end

  private

  def strava_api
    StravaApi::StravaApiRequest.new
  end

  def update_user_tokens(response)
    current_user.strava_access_token = response.access_token
    current_user.strava_refresh_token = response.refresh_token
    current_user.strava_expires_at = response.expires_at

    current_user.save
  end
end
