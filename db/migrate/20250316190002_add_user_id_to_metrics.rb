class AddUserIdToMetrics < ActiveRecord::Migration[7.1]
  def change
    add_column :metrics, :user_id, :integer
    add_index :metrics, :user_id
  end
end
