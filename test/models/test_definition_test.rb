# frozen_string_literal: true

require "test_helper"

class TestDefinitionTest < ActiveSupport::TestCase
  test "validates exact response requirements" do
    definition = TestDefinition.new(
      name: "Exact",
      prompt: "Hi",
      response_type: "exact",
      llm_model: llm_models(:llama),
      frequency_minutes: 10
    )

    assert_not definition.valid?
    assert_includes definition.errors[:expected_response], "can't be blank"
  end

  test "validates approximate regex requirements" do
    definition = TestDefinition.new(
      name: "Approx",
      prompt: "Hi",
      response_type: "approximate",
      llm_model: llm_models(:llama),
      frequency_minutes: 10
    )

    assert_not definition.valid?
    assert_includes definition.errors[:regex_pattern], "can't be blank"
  end

  test "allows all models without a specific model" do
    definition = TestDefinition.new(
      name: "Everywhere",
      prompt: "Hi",
      response_type: "any",
      run_on_all_models: true,
      frequency_minutes: 10
    )

    assert_predicate definition, :valid?
    assert_equal LlmModel.enabled.count, definition.target_models.count
  end

  test "all models target excludes disabled models" do
    definition = test_definitions(:all_models_ping)

    assert_not_includes definition.target_models, llm_models(:disabled_model)
    assert_includes definition.target_models, llm_models(:llama)
  end

  test "clears model when run on all models" do
    definition = test_definitions(:exact_greeting)
    definition.run_on_all_models = true

    assert definition.valid?
    assert_nil definition.llm_model_id
  end

  test "rejects invalid regex" do
    definition = test_definitions(:approximate_greeting)
    definition.regex_pattern = "[unclosed"

    assert_not definition.valid?
    assert_includes definition.errors[:regex_pattern].first, "is invalid"
  end

  test "due_for_run when never run" do
    definition = test_definitions(:exact_greeting)
    assert definition.due_for_run?
  end

  test "due_for_run when interval elapsed" do
    definition = test_definitions(:approximate_greeting)
    assert definition.due_for_run?
  end

  test "not due when recently run" do
    definition = test_definitions(:exact_greeting)
    definition.update!(last_run_at: 1.minute.ago)
    assert_not definition.due_for_run?
  end

  test "due_for_run scope excludes disabled tests" do
    due_ids = TestDefinition.due_for_run.map(&:id)
    assert_not_includes due_ids, test_definitions(:disabled_test).id
  end

  test "latest_run_for returns run for specific model" do
    definition = test_definitions(:all_models_ping)
    model = llm_models(:llama)

    run = definition.test_runs.create!(
      llm_model: model,
      server: model.server,
      status: "passed",
      actual_response: "pong",
      started_at: Time.current,
      finished_at: Time.current
    )

    assert_equal run, definition.latest_run_for(model)
  end
end
