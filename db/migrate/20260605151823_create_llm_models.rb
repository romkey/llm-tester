class CreateLlmModels < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_models do |t|
      t.string :name, null: false
      t.references :server, null: false, foreign_key: true

      t.timestamps
    end

    add_index :llm_models, [ :server_id, :name ], unique: true
  end
end
