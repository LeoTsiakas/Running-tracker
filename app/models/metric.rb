class Metric < ApplicationRecord
  validates :time, :distance, :date, presence: true
  validate :date_cannot_be_in_the_future

  belongs_to :user

  scope :ordered, -> { order(date: :asc) }

  private

  def date_cannot_be_in_the_future
    errors.add(:date, "can't be in the future") if date.in_time_zone > Time.current
  end
end
