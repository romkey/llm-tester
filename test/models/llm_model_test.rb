# frozen_string_literal: true

require "test_helper"

class LlmModelTest < ActiveSupport::TestCase
  test "validates name uniqueness per server" do
    duplicate = LlmModel.new(name: llm_models(:llama).name, server: servers(:ollama))
    assert_not duplicate.valid?
  end

  test "defaults benchmark latency mode to generation" do
    model = LlmModel.create!(name: "fresh-model", server: servers(:ollama))
    assert_equal "generation", model.benchmark_latency_mode
  end

  test "enables benchmark prompt adaptation by default" do
    model = LlmModel.create!(name: "adapt-model", server: servers(:ollama))
    assert model.benchmark_adapt_prompt
  end

  test "rejects an unknown benchmark latency mode" do
    model = LlmModel.new(name: "x", server: servers(:ollama), benchmark_latency_mode: "bogus")
    assert_not model.valid?
    assert_includes model.errors[:benchmark_latency_mode], "is not included in the list"
  end

  test "accepts supported benchmark latency modes" do
    LlmModel::BENCHMARK_LATENCY_MODES.each do |mode|
      model = LlmModel.new(name: "model-#{mode}", server: servers(:ollama), benchmark_latency_mode: mode)
      assert model.valid?, "expected #{mode} to be valid"
    end
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

  test "disabled model reports disabled health status" do
    model = llm_models(:disabled_model)
    assert_equal :disabled, model.health_status
    assert model.healthy?
  end

  test "for_selection includes current model when disabled" do
    model = llm_models(:disabled_model)
    selection = LlmModel.for_selection(current_id: model.id)

    assert_includes selection, model
  end

  test "for_selection excludes disabled models without current id" do
    selection = LlmModel.for_selection

    assert_not_includes selection, llm_models(:disabled_model)
    assert_includes selection, llm_models(:llama)
  end
end
