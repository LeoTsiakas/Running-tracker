class CreateMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :metrics do |t|
      t.string :time
      t.integer :distance

      t.timestamps
    end
  end
end
