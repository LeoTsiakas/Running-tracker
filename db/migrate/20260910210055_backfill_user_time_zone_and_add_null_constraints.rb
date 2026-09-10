class BackfillUserTimeZoneAndAddNullConstraints < ActiveRecord::Migration[7.1]
  def up
    User.where(time_zone: [nil, '']).update_all(time_zone: 'UTC')

    change_column_null :users, :time_zone, false
    change_column_null :metrics, :distance, false
  end

  def down
    change_column_null :metrics, :distance, true
    change_column_null :users, :time_zone, true
  end
end
