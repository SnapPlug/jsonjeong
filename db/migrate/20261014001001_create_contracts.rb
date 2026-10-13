class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :amount, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :status, null: false, default: "in_progress"
      t.string :business_number
      t.text :notes
      t.timestamps
    end
  end
end
