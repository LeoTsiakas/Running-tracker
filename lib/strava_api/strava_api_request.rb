module StravaApi
  class StravaApiRequest
    def initialize
    end

    def authorize
      redirect_to strava_client.authorize_url(
        redirect_uri: api_v1_auth_strava_callback_url,
        approval_prompt: 'force',
        response_type: 'code',
        scope: 'activity:read_all',
        state: 'magic'
      ), allow_other_host: true
    end

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

    def fetch_athlete_activities(access_token)
      client = Strava::Api::Client.new(access_token: access_token)
      client.athlete_activities.collection
    end
  end
end
