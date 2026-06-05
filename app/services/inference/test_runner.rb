# frozen_string_literal: true

module Inference
  class TestRunner
    def self.run(definition, llm_model: definition.llm_model)
      new(definition, llm_model: llm_model).run
    end

    def initialize(definition, llm_model:)
      @definition = definition
      @llm_model = llm_model
      raise ArgumentError, "llm_model is required" if @llm_model.nil?
    end

    def run
      started_at = Time.current
      result = nil
      error_message = nil
      status = "passed"

      begin
        client = Client.for(@llm_model.server)
        result = client.complete(@llm_model.name, definition.prompt)
        status = ResponseMatcher.match?(definition, result.text) ? "passed" : "failed"
      rescue Error => e
        status = "error"
        error_message = e.message
      end

      TestRun.create!(
        test_definition: definition,
        llm_model: @llm_model,
        server: @llm_model.server,
        status: status,
        actual_response: result&.text,
        error_message: error_message,
        started_at: started_at,
        finished_at: Time.current,
        latency_ms: result&.latency_ms,
        tokens_per_second: result&.tokens_per_second,
        prompt_tokens: result&.prompt_tokens,
        completion_tokens: result&.completion_tokens
      )
    end

    private

    attr_reader :definition
  end
end
