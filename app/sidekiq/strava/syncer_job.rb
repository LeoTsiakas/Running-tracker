require 'sidekiq-scheduler'

class Strava::SyncerJob
  include Sidekiq::Job

  def perform(*args)
    User.where.not(strava_access_token: nil).find_each do |user|
      Strava::UserSyncJob.perform_async(user.id)
    end
  end
end
