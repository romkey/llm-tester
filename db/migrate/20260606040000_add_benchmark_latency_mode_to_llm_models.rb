class AddBenchmarkLatencyModeToLlmModels < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_models, :benchmark_latency_mode, :string, null: false, default: "generation"
  end
end
