# frozen_string_literal: true

require "test_helper"

class LlmModelsControllerTest < ActionDispatch::IntegrationTest
  test "show lists applicable health checks for a healthy model" do
    model = llm_models(:llama)

    get llm_model_url(model)

    assert_response :success
    assert_select "h1", model.name
    assert_select ".badge", text: "Healthy"
    assert_select "td", text: test_definitions(:exact_greeting).name
    assert_select "td", text: "Passed."
  end

  test "show surfaces the error reason for an unhealthy model" do
    model = llm_models(:llama)
    message = "Could not reach Ollama server: Connection refused"

    TestRun.create!(
      test_definition: test_definitions(:exact_greeting),
      llm_model: model,
      server: model.server,
      status: "error",
      error_message: message,
      started_at: Time.current,
      finished_at: Time.current
    )

    get llm_model_url(model)

    assert_response :success
    assert_select ".badge", text: "Unhealthy"
    assert_select "td", text: message
  end

  test "show explains when a check has never run" do
    model = llm_models(:llama)
    TestDefinition.create!(
      name: "Never run check",
      prompt: "ping",
      response_type: "any",
      frequency_minutes: 60,
      llm_model: model,
      enabled: true
    )

    get llm_model_url(model)

    assert_response :success
    assert_select "td", text: "Test has not been run yet."
  end

  test "show notes when a model is disabled" do
    get llm_model_url(llm_models(:disabled_model))

    assert_response :success
    assert_select ".alert", /disabled/
  end
end
