class AddBenchmarkAdaptPromptToLlmModels < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_models, :benchmark_adapt_prompt, :boolean, null: false, default: true
  end
end
