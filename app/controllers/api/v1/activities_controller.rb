class Api::V1::ActivitiesController < ApplicationController
  def fetch_athlete_activities(access_token)
    client = Strava::Client.new(access_token: access_token)
    client.athlete_activities

    update_athlete_activities(client.athlete_activities)
  end

  def update_athlete_activities(athlete)
  end
end
