class AddStackVersionToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :stack_version, :string
  end
end
