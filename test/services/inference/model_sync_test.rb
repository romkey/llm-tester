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

  test "creates models from openai compatible server" do
    stub_request(:get, "https://api.example.com/v1/models")
      .to_return(status: 200, body: { data: [ { id: "new-openai-model" } ] }.to_json)

    server = servers(:openai)
    created = Inference::ModelSync.sync(server)

    assert_equal 1, created.size
    assert_equal "new-openai-model", created.first.name
    assert server.llm_models.exists?(name: "new-openai-model")
  end
end
