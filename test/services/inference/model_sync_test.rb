# frozen_string_literal: true

require "test_helper"

class InferenceModelSyncTest < ActiveSupport::TestCase
  test "creates models from remote list" do
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_return(status: 200, body: { models: [ { name: "llama3" }, { name: "new-model" } ] }.to_json)

    server = servers(:ollama)
    created = Inference::ModelSync.sync(server)

    assert_equal 1, created.size
    assert_equal "new-model", created.first.name
    assert server.llm_models.exists?(name: "new-model")
  end
end
