# frozen_string_literal: true

require "test_helper"

module Settings
  class TestDefinitionsControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper
    test "create test definition" do
      assert_difference "TestDefinition.count", 1 do
        post settings_test_definitions_url, params: {
          test_definition: {
            name: "New exact test",
            prompt: "Say hi",
            response_type: "exact",
            expected_response: "hi",
            frequency_minutes: 30,
            llm_model_id: llm_models(:llama).id,
            enabled: true
          }
        }
      end

      assert_redirected_to settings_test_definitions_url
    end

    test "run_now enqueues job" do
      definition = test_definitions(:exact_greeting)

      assert_enqueued_with(job: RunTestJob, args: [ definition.id ]) do
        post run_now_settings_test_definition_url(definition)
      end

      assert_redirected_to settings_test_definitions_url
    end
  end
end
