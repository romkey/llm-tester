class CreateBenchmarkRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :benchmark_runs do |t|
      t.references :llm_model, null: false, foreign_key: true
      t.references :server, null: false, foreign_key: true
      t.string :status, null: false
      t.text :error_message
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :prompt_tokens
      t.integer :generation_tokens
      t.integer :context_depth
      t.float :prompt_tokens_per_second
      t.float :generation_tokens_per_second
      t.float :peak_generation_tokens_per_second
      t.float :time_to_first_token_ms
      t.float :estimated_prompt_processing_ms
      t.text :raw_report

      t.timestamps
    end

    add_index :benchmark_runs, :created_at
  end
end
