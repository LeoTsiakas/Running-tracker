class Metric < ApplicationRecord
  validates :time, :distance, :date, presence: true
  validates :distance, numericality: { greater_than: 0 }
  validate :date_cannot_be_in_the_future

  validates :distance, comparison: { greater_than: 0 }

  belongs_to :user

  scope :ordered, -> { order(date: :asc) }

  after_create_commit do
    TypesenseService.index_metric(self)
  end

  after_update_commit do
    TypesenseService.update_metric(self)
  end

  after_destroy_commit do
    TypesenseService.delete_metric(self)
  end

  private

  def date_cannot_be_in_the_future
    return if date.blank?

    Time.use_zone(user&.time_zone.presence || Time.zone.name) do
      local_date = Time.zone.local(date.year, date.month, date.day, date.hour, date.min, date.sec)
      errors.add(:date, "can't be in the future") if local_date > Time.current
    end
  end
end
