class AddDefaultValueToUserTimeZone < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :time_zone, 'UTC'
  end
end
