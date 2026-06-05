class CreateTestRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :test_runs do |t|
      t.references :test_definition, null: false, foreign_key: true
      t.references :llm_model, null: false, foreign_key: true
      t.references :server, null: false, foreign_key: true
      t.string :status, null: false
      t.text :actual_response
      t.text :error_message
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :test_runs, :created_at
    add_index :test_runs, :status
  end
end
