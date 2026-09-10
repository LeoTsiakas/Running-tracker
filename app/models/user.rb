class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2]

  has_many :metrics, dependent: :destroy

  before_validation :normalize_time_zone

  validates :time_zone, presence: true

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

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    return nil unless auth.info.email.present? && auth.extra.raw_info.email_verified

    user = find_or_initialize_by(email: auth.info.email)
    user.assign_attributes(provider: auth.provider, uid: auth.uid)

    if user.new_record?
      user.username  = auth.info.name
      user.time_zone = 'UTC'
      user.password  = Devise.friendly_token(32)
    end

    user.save ? user : nil
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
