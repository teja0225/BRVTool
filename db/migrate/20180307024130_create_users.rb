class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :u
      t.string :p
      t.string :d
      t.string :t
      t.string :f
      t.string :dir
      t.string :du
      t.string :dp
      t.integer :all

      t.timestamps
    end
  end
end
