# frozen_string_literal: true

require "test_helper"

class InferenceOllamaClientTest < ActiveSupport::TestCase
  setup do
    @server = servers(:ollama)
    @client = Inference::OllamaClient.new(@server)
  end

  test "list_models parses tags response" do
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_return(status: 200, body: { models: [ { name: "llama3" }, { name: "mistral" } ] }.to_json)

    assert_equal %w[llama3 mistral], @client.list_models
  end

  test "complete returns response text" do
    stub_request(:post, "http://localhost:11434/api/generate")
      .with(body: hash_including("model" => "llama3", "prompt" => "Hi"))
      .to_return(status: 200, body: { response: "Hello!" }.to_json)

    assert_equal "Hello!", @client.complete("llama3", "Hi")
  end

  test "raises inference error on connection failure" do
    stub_request(:get, "http://localhost:11434/api/tags").to_raise(Errno::ECONNREFUSED)

    assert_raises(Inference::Error) { @client.list_models }
  end
end
