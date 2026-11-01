class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.string :token, null: false
      t.string :status, null: false, default: "pending"
      t.string :locale, null: false, default: "ko"
      t.string :name, null: false
      t.string :url
      t.string :email, null: false
      t.date :started_on, null: false
      t.date :ended_on
      t.decimal :hours, precision: 8, scale: 1, null: false
      t.decimal :cost_usd, precision: 10, scale: 2, null: false
      t.decimal :revenue_usd, precision: 10, scale: 2, null: false
      t.text :stuck, null: false
      t.text :quit_signal, null: false
      t.string :tools
      t.string :proof_url
      t.timestamps
    end
    add_index :submissions, :token, unique: true
    add_index :submissions, :status
  end
end
