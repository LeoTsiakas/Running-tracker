class Api::V1::AuthenticationController < ApplicationController
  before_action :set_current_user

  def start
    redirect_to strava_client.authorize_url(
      redirect_uri: api_v1_auth_strava_callback_url,
      approval_prompt: 'force',
      response_type: 'code',
      scope: 'activity:read_all',
      state: 'magic'
    ), allow_other_host: true
  end

  def callback
    if params[:error].present?
      return redirect_to sign_in_path, status: :unprocessable_entity, alert: 'Authorization failed. Please try again.'
    end

    response = fetch_access_token(params[:code])

    update_user_strava_id(response.athlete.id) if Current.user.strava_id.blank?

    Api::V1::ActivitiesController.new(response)
  end

  private

  def strava_client
    @strava_client ||= Strava::OAuth::Client.new(
      client_id: Rails.application.credentials.dig(:strava, :client_id),
      client_secret: Rails.application.credentials.dig(:strava, :client_secret)
    )
  end

  def fetch_access_token(code)
    response = strava_client.oauth_token(code: code)
    return response unless Time.now > Time.at(response.expires_at)

    strava_client.oauth_token(
      refresh_token: response.refresh_token,
      grant_type: 'refresh_token'
    )
  end

  def update_user_strava_id(strava_id)
    Current.user.update(strava_id: strava_id)
  end
end
