class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "other"
      t.string :status, null: false, default: "active"
      t.string :health_url
      t.string :vercel_project_id
      t.string :vercel_team_id
      t.string :supabase_ref
      t.text :notes
      t.timestamps
    end
    add_index :clients, :name, unique: true
  end
end
