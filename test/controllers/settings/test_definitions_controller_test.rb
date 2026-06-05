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

    test "create all models test definition" do
      assert_difference "TestDefinition.count", 1 do
        post settings_test_definitions_url, params: {
          test_definition: {
            name: "Global test",
            prompt: "Say hi",
            response_type: "any",
            frequency_minutes: 30,
            run_on_all_models: true,
            enabled: true
          }
        }
      end

      definition = TestDefinition.order(:id).last
      assert definition.run_on_all_models?
      assert_nil definition.llm_model_id
      assert_redirected_to settings_test_definitions_url
    end

    test "run_now enqueues job" do
      definition = test_definitions(:exact_greeting)

      assert_enqueued_with(job: RunTestJob, args: [ definition.id ]) do
        post run_now_settings_test_definition_url(definition)
      end

      assert_redirected_to settings_test_definitions_url
    end

    test "create test definition with image" do
      assert_difference "TestDefinition.count", 1 do
        post settings_test_definitions_url, params: {
          test_definition: {
            name: "Vision test",
            prompt: "Describe the image",
            response_type: "any",
            frequency_minutes: 30,
            llm_model_id: llm_models(:llama).id,
            enabled: true,
            image: fixture_file_upload("sample.png", "image/png")
          }
        }
      end

      definition = TestDefinition.order(:id).last
      assert definition.image.attached?
      assert_redirected_to settings_test_definitions_url
    end

    test "update removes image when requested" do
      definition = test_definitions(:exact_greeting)
      definition.image.attach(
        io: File.open(file_fixture("sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )

      patch settings_test_definition_url(definition), params: {
        test_definition: {
          name: definition.name,
          prompt: definition.prompt,
          response_type: definition.response_type,
          expected_response: definition.expected_response,
          frequency_minutes: definition.frequency_minutes,
          llm_model_id: definition.llm_model_id,
          enabled: definition.enabled,
          remove_image: "1"
        }
      }

      assert_redirected_to settings_test_definitions_url
      assert_not definition.reload.image.attached?
    end
  end
end
