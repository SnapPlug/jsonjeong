class CreateHealthLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :health_logs do |t|
      t.references :client, null: false, foreign_key: true
      t.string :check_type, null: false
      t.boolean :ok, null: false
      t.integer :status_code
      t.integer :ms
      t.string :error
      t.datetime :checked_at, null: false
    end
    add_index :health_logs, [ :client_id, :check_type, :checked_at ]
    add_index :health_logs, :checked_at
  end
end
