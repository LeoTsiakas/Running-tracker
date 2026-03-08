class AddTokensToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :strava_access_token, :string
    add_column :users, :strava_refresh_token, :string
    add_column :users, :strava_expires_at, :datetime
  end
end
