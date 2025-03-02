class Metric < ApplicationRecord
  validates :time, :distance, :date, presence: true

  scope :ordered, -> { order(date: :asc) }
end
