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

  test "complete returns response text and metrics" do
    stub_request(:post, "http://localhost:11434/api/generate")
      .with(body: hash_including("model" => "llama3", "prompt" => "Hi"))
      .to_return(status: 200, body: {
        response: "Hello!",
        eval_count: 8,
        eval_duration: 160_000_000,
        prompt_eval_count: 3
      }.to_json)

    result = @client.complete("llama3", "Hi")
    assert_equal "Hello!", result.text
    assert_equal 8, result.completion_tokens
    assert_in_delta 50.0, result.tokens_per_second
  end

  test "raises inference error on connection failure" do
    stub_request(:get, "http://localhost:11434/api/tags").to_raise(Errno::ECONNREFUSED)

    assert_raises(Inference::Error) { @client.list_models }
  end
end
