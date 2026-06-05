class CreateServers < ActiveRecord::Migration[8.1]
  def change
    create_table :servers do |t|
      t.string :name, null: false
      t.string :hostname, null: false
      t.string :api_type, null: false
      t.string :api_key

      t.timestamps
    end

    add_index :servers, :name, unique: true
  end
end
