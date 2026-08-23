class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :metrics, dependent: :destroy

  before_validation :normalize_time_zone

  def metrics_by_registered_at
    metrics.each_with_object({}) { |m, h| h[m.date.utc] = m }
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

  private

  # The forms submit the browser's IANA identifier ("Europe/Athens"). Store the
  # ActiveSupport name ("Athens") so the zone is always spelled one way. MAPPING.key
  # is nil for a name that's already converted, hence the fallback.
  def normalize_time_zone
    self.time_zone = if time_zone.blank?
                       nil
                     else
                       ActiveSupport::TimeZone::MAPPING.key(time_zone) || time_zone
                     end
  end
end
