class Metric < ApplicationRecord
  validates :time, :distance, :date, presence: true

  validates :distance, comparison: { greater_than: 0 }

  belongs_to :user

  scope :ordered, -> { order(date: :asc) }
end
