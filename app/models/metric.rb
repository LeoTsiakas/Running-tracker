class Metric < ApplicationRecord
  validates :time, :distance, :date, presence: true

  belongs_to :user

  scope :ordered, -> { order(date: :asc) }
end
