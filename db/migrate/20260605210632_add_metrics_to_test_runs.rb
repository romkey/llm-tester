class AddMetricsToTestRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :test_runs, :latency_ms, :float
    add_column :test_runs, :tokens_per_second, :float
    add_column :test_runs, :prompt_tokens, :integer
    add_column :test_runs, :completion_tokens, :integer
  end
end
