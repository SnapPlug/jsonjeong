class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :source, null: false, default: "site"
      t.string :status, null: false, default: "pending"
      t.datetime :beehiiv_synced_at

      t.timestamps
    end
    add_index :subscribers, :email, unique: true
  end
end
