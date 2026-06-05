# frozen_string_literal: true

require "test_helper"

module Settings
  class LlmModelsControllerTest < ActionDispatch::IntegrationTest
    test "create model" do
      assert_difference "LlmModel.count", 1 do
        post settings_llm_models_url, params: {
          llm_model: { name: "manual-model", server_id: servers(:ollama).id }
        }
      end

      assert_redirected_to settings_llm_models_url
    end

    test "update enabled flag" do
      model = llm_models(:llama)

      patch settings_llm_model_url(model), params: {
        llm_model: { name: model.name, server_id: model.server_id, enabled: false }
      }

      assert_redirected_to settings_llm_models_url
      assert_not model.reload.enabled?
    end
  end
end
