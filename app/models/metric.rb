class Metric < ApplicationRecord
  include Typesense

  typesense do
    attributes :user_id, :time, :distance
    attribute(:date) { date.to_i }

    default_sorting_field :date

    predefined_fields [
      { name: 'user_id', type: 'int32' },
      { name: 'time', type: 'int32' },
      { name: 'distance', type: 'float' },
      { name: 'date', type: 'int64' }
    ]
  end

  validates :time, :distance, :date, presence: true
  validates :distance, numericality: { greater_than: 0 }
  validate :date_cannot_be_in_the_future

  validates :distance, comparison: { greater_than: 0 }

  belongs_to :user

  scope :ordered, -> { order(date: :asc) }

  private

  def date_cannot_be_in_the_future
    return if date.blank?

    Time.use_zone(user&.time_zone.presence || Time.zone.name) do
      local_date = Time.zone.local(date.year, date.month, date.day, date.hour, date.min, date.sec)
      errors.add(:date, "can't be in the future") if local_date > Time.current
    end
  end
end
