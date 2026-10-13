class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :contract, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :amount, null: false
      t.date :due_on, null: false
      t.date :paid_on
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
  end
end
