class AddHostToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :host, :string
  end
end
