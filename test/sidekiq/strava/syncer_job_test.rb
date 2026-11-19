require 'test_helper'

class Strava::SyncerJobTest < ActiveSupport::TestCase
  setup { Sidekiq::Job.clear_all }

  test 'enqueues a sync for every user connected to Strava' do
    users(:one).update_columns(strava_access_token: 'token')

    Strava::SyncerJob.new.perform

    assert_equal [[users(:one).id]], Strava::UserSyncJob.jobs.pluck('args')
  end

  test 'enqueues nothing when no user is connected to Strava' do
    Strava::SyncerJob.new.perform

    assert_empty Strava::UserSyncJob.jobs
  end

  test 'every job in the Sidekiq schedule points to an existing class' do
    schedule = YAML.load_file(Rails.root.join('config/sidekiq.yml')).dig(:scheduler, :schedule)

    assert_equal 'Strava::SyncerJob', schedule.dig('strava_sync', 'class')
    schedule.each_value { |job| assert_nothing_raised { job['class'].constantize } }
  end
end
