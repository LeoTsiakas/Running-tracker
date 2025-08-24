class Api::V1::AuthenticationController < ApplicationController
  before_action :set_current_user

  def initialize
    @strava_api = StravaApi::StravaApiRequest.new
    @strava_api.authorize
  end

  def callback
    if params[:error].present?
      return redirect_to sign_in_path, status: :unprocessable_entity, alert: 'Authorization failed. Please try again.'
    end

    response = @strava_api.fetch_access_token(params[:code])

    Current.user.update_user_strava_id(response.athlete.id) if Current.user.strava_id.blank?

    athlete_activities = @strava_api.fetch_athlete_activities(response.access_token)
    Current.user.update_athlete_activities(athlete_activities)

    redirect_to root_path, notice: 'Successfully authenticated with Strava.'
  end
end
