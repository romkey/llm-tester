# frozen_string_literal: true

class RunTestJob < ApplicationJob
  queue_as :default

  def perform(test_definition_id)
    definition = TestDefinition.find(test_definition_id)

    if definition.run_on_all_models?
      definition.target_models.find_each do |model|
        Inference::TestRunner.run(definition, llm_model: model)
      end
    else
      Inference::TestRunner.run(definition)
    end

    definition.update!(last_run_at: Time.current)
  end
end
