class Metric < ApplicationRecord
  validates :time, :distance, :date, presence: true
  validates :distance, numericality: { greater_than: 0 }
  validate :date_cannot_be_in_the_future

  belongs_to :user

  scope :ordered, -> { order(date: :asc) }

  private

  def date_cannot_be_in_the_future
    Time.use_zone(Current.user.time_zone) do
      local_date = Time.zone.local(date.year, date.month, date.day, date.hour, date.min, date.sec)
      errors.add(:date, "can't be in the future") if local_date > Time.current
    end
  end
end
