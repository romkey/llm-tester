# frozen_string_literal: true

class RunModelBenchmarkJob < ApplicationJob
  queue_as :default

  def perform(llm_model_id)
    model = LlmModel.find(llm_model_id)
    Inference::BenchRunner.run(model)
  end
end
