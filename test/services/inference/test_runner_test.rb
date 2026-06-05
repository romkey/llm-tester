# frozen_string_literal: true

require "test_helper"

class InferenceTestRunnerTest < ActiveSupport::TestCase
  test "records passed run and updates last_run_at" do
    definition = test_definitions(:exact_greeting)

    stub_request(:post, "http://localhost:11434/api/generate")
      .to_return(status: 200, body: { response: "Hello!" }.to_json)

    assert_difference "TestRun.count", 1 do
      run = Inference::TestRunner.run(definition)
      assert run.passed?
      assert_equal "Hello!", run.actual_response
    end
  end

  test "records failed run when response does not match" do
    definition = test_definitions(:exact_greeting)

    stub_request(:post, "http://localhost:11434/api/generate")
      .to_return(status: 200, body: { response: "Nope" }.to_json)

    run = Inference::TestRunner.run(definition)
    assert run.failed?
  end

  test "records error run when request fails" do
    definition = test_definitions(:exact_greeting)

    stub_request(:post, "http://localhost:11434/api/generate").to_raise(Errno::ECONNREFUSED)

    run = Inference::TestRunner.run(definition)
    assert run.error?
    assert_includes run.error_message, "Could not reach Ollama server"
  end
end
