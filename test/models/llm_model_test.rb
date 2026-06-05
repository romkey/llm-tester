# frozen_string_literal: true

require "test_helper"

class LlmModelTest < ActiveSupport::TestCase
  test "validates name uniqueness per server" do
    duplicate = LlmModel.new(name: llm_models(:llama).name, server: servers(:ollama))
    assert_not duplicate.valid?
  end

  test "healthy when enabled tests all passed" do
    assert llm_models(:llama).healthy?
  end

  test "includes all-models tests in health check" do
    model = llm_models(:llama)
    definition = test_definitions(:all_models_ping)

    definition.test_runs.create!(
      llm_model: model,
      server: model.server,
      status: "failed",
      actual_response: "nope",
      started_at: Time.current,
      finished_at: Time.current
    )

    assert_not model.healthy?
    assert_includes model.applicable_test_definitions, definition
  end

  test "unhealthy when latest enabled test failed" do
    model = llm_models(:llama)
    test_definitions(:approximate_greeting).test_runs.create!(
      llm_model: model,
      server: model.server,
      status: "failed",
      actual_response: "bad",
      started_at: Time.current,
      finished_at: Time.current
    )

    assert_not model.healthy?
  end

  test "unknown health when no enabled tests" do
    model = llm_models(:llama)
    model.test_definitions.update_all(enabled: false)
    TestDefinition.where(run_on_all_models: true).update_all(enabled: false)
    assert_equal :unknown, model.health_status
  end

  test "label_with_server includes server name" do
    model = llm_models(:llama)
    assert_equal "llama3 (Ollama Local)", model.label_with_server
  end
end
