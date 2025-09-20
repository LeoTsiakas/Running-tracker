class Api::V1::AuthenticationController < ApplicationController
  before_action :set_current_user

  def start
    if Current.user.strava_access_token.present?
      if Current.user.strava_expires_at > Time.now
        athlete_activities = strava_api.fetch_athlete_activities(Current.user.strava_access_token)
        Current.user.update_athlete_activities(athlete_activities)

        redirect_to root_path, notice: 'Strava activities synced!'
      else
        response = strava_api.refresh_access_token(Current.user.strava_refresh_token)

        update_user_tokens(response)
    
        start
      end 
    else
      redirect_to strava_api.authorize, allow_other_host: true
    end
  end

  def callback
    if params[:error].present?
      return redirect_to sign_in_path, status: :unprocessable_entity, alert: 'Authorization failed. Please try again.'
    end

    response = strava_api.fetch_access_token(params[:code])

    update_user_tokens(response)
    athlete_activities = strava_api.fetch_athlete_activities(Current.user.strava_access_token)
    Current.user.update_athlete_activities(athlete_activities)

    redirect_to root_path, notice: 'Strava activities synced!'
  end

  private

  def strava_api
    StravaApi::StravaApiRequest.new
  end

  def update_user_tokens(response)
    Current.user.strava_access_token = response.access_token
    Current.user.strava_refresh_token = response.refresh_token
    Current.user.strava_expires_at = response.expires_at

    Current.user.save
  end
end