class AddSupabaseRegionToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :supabase_region, :string
  end
end
