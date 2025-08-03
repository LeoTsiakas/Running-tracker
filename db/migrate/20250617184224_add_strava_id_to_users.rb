class AddStravaIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :strava_id, :integer, null: true
    add_index :users, :strava_id, unique: true
  end
end
