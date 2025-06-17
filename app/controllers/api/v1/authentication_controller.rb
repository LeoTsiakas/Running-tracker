class Api::V1::AuthenticationController < ApplicationController
  def authenticate
    # Check if this is the first time the user tries to log in through strava
    # # use strava_id for this purpose
    # Create strava_id column
    strava_authorization_url = strava_client.authorize_url(
      redirect_uri: 'http://localhost:3000/auth/strava/callback',
      approval_prompt: 'force',
      response_type: 'code',
      scope: 'activity:read_all',
      state: 'magic'
    )

    redirect_to strava_authorization_url, allow_other_host: true
  end

  def callback
    if params[:error].present?
      redirect_to sign_in_path, status: :unprocessable_entity, alert: 'Authorization failed. Please try again.'
    end
    # check params[:error] here to check if user has given required permissions
    response = strava_client.oauth_token(code: params[:code])

    if Time.now > Time.at(response.expires_at)
      response = strava_client.oauth_token(
        refresh_token: response.refresh_token,
        grant_type: 'refresh_token'
      )
    end

    strava_access_token = response.access_token
    strava_refresh_token = response.refresh_token
    strava_athlete = response.athlete
    strava_id = strava_athlete.id

    update_user_strava_id(strava_id) if Current.user.strava_id.blank?
  end

  def update_user_strava_id(strava_id)
    Current.user.update(strava_id: strava_id)
  end

  private

  def strava_client
    @strava_client ||= Strava::OAuth::Client.new(
      client_id: Rails.application.credentials.dig(:strava, :client_id),
      client_secret: Rails.application.credentials.dig(:strava, :client_secret)
    )
  end
end
