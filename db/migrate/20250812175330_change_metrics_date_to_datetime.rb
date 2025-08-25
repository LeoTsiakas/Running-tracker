class ChangeMetricsDateToDatetime < ActiveRecord::Migration[7.1]
  def change
    change_column :metrics, :date, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }

    Metric.all.each do |metric|
      metric.update(date: metric.date.to_datetime) if metric.date.is_a?(Date)
    end
  end
end
