class AddServerHostToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :server_host, :string
  end
end
