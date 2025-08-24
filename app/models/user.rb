class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true

  has_many :metrics, dependent: :destroy

  def metrics_by_registered_at
    metrics.each_with_object({}) { |m, h| h[m.date.utc] = m }
  end

  def update_user_strava_id(strava_id)
    update(strava_id: strava_id)
  end

  def update_athlete_activities(activities)
    activities.each do |row|
      time = (row.elapsed_time / 60.0).round(2).to_s.gsub('.', ':')

      activity = if metrics_by_registered_at[row.start_date_local.utc].present?
                   next
                 else
                   metrics.new(
                     time: time,
                     distance: row.distance / 1000, # check integer or float
                     date: row.start_date_local.to_datetime
                   )
                 end

      activity.save
    end
  end
end
