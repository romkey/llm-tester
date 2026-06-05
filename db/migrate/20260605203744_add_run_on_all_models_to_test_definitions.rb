class AddRunOnAllModelsToTestDefinitions < ActiveRecord::Migration[8.1]
  def change
    add_column :test_definitions, :run_on_all_models, :boolean, null: false, default: false
    change_column_null :test_definitions, :llm_model_id, true
  end
end
