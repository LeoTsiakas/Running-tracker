class Strava::SyncerJob
  include Sidekiq::Job

  def perform(*args)
    StravaApi::StravaApiRequest.new
  end
end
