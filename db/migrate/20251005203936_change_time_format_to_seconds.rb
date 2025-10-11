class ChangeTimeFormatToSeconds < ActiveRecord::Migration[7.1]
  def change
    change_column :metrics, :time, :integer, null: false
  end
end
