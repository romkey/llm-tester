class CreateTestDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :test_definitions do |t|
      t.string :name, null: false
      t.text :prompt, null: false
      t.string :response_type, null: false, default: "exact"
      t.text :expected_response
      t.string :regex_pattern
      t.integer :frequency_minutes, null: false, default: 60
      t.references :llm_model, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: true
      t.datetime :last_run_at

      t.timestamps
    end
  end
end
