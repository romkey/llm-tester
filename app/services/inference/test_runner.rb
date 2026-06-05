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
      actual_response = nil
      error_message = nil
      status = "passed"

      begin
        client = Client.for(@llm_model.server)
        actual_response = client.complete(@llm_model.name, definition.prompt)
        status = ResponseMatcher.match?(definition, actual_response) ? "passed" : "failed"
      rescue Error => e
        status = "error"
        error_message = e.message
      end

      finished_at = Time.current

      TestRun.create!(
        test_definition: definition,
        llm_model: @llm_model,
        server: @llm_model.server,
        status: status,
        actual_response: actual_response,
        error_message: error_message,
        started_at: started_at,
        finished_at: finished_at
      )
    end

    private

    attr_reader :definition
  end
end
