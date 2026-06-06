# frozen_string_literal: true

class RunModelBenchmarkJob < ApplicationJob
  queue_as :default

  def perform(llm_model_id)
    model = LlmModel.find(llm_model_id)
    return unless model.enabled?

    Inference::BenchRunner.run(
      model,
      latency_mode: model.benchmark_latency_mode,
      adapt_prompt: model.benchmark_adapt_prompt
    )
  end
end
