class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true

  has_many :metrics, dependent: :destroy

  def metrics_by_registered_at
    Current.user.metrics.each_with_object({}) { |m, h| h[m.date.utc] = m }
  end
end
