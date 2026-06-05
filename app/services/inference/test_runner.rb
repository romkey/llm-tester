# frozen_string_literal: true

module Inference
  class TestRunner
    def self.run(definition)
      new(definition).run
    end

    def initialize(definition)
      @definition = definition
    end

    def run
      started_at = Time.current
      actual_response = nil
      error_message = nil
      status = "passed"

      begin
        client = Client.for(definition.server)
        actual_response = client.complete(definition.llm_model.name, definition.prompt)
        status = ResponseMatcher.match?(definition, actual_response) ? "passed" : "failed"
      rescue Error => e
        status = "error"
        error_message = e.message
      end

      finished_at = Time.current

      test_run = TestRun.create!(
        test_definition: definition,
        llm_model: definition.llm_model,
        server: definition.server,
        status: status,
        actual_response: actual_response,
        error_message: error_message,
        started_at: started_at,
        finished_at: finished_at
      )

      definition.update!(last_run_at: finished_at)
      test_run
    end

    private

    attr_reader :definition
  end
end
