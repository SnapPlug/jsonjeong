class CreateWorkLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :work_logs do |t|
      t.references :client, null: false, foreign_key: true
      t.date :worked_on, null: false
      t.integer :minutes, null: false
      t.string :kind, null: false
      t.string :note
      t.timestamps
    end
  end
end
