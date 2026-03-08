class ChangeMetricDistanceType < ActiveRecord::Migration[7.1]
  def change
    change_column :metrics, :distance, :float
  end
end
