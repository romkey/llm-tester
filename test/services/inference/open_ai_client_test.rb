# frozen_string_literal: true

require "test_helper"

class InferenceOpenAiClientTest < ActiveSupport::TestCase
  setup do
    @server = servers(:openai)
    @client = Inference::OpenAiClient.new(@server)
  end

  test "list_models parses model ids" do
    stub_request(:get, "https://api.example.com/v1/models")
      .with(headers: { "Authorization" => "Bearer test-key" })
      .to_return(status: 200, body: { data: [ { id: "gpt-4o-mini" } ] }.to_json)

    assert_equal [ "gpt-4o-mini" ], @client.list_models
  end

  test "complete returns message content" do
    stub_request(:post, "https://api.example.com/v1/chat/completions")
      .to_return(status: 200, body: {
        choices: [ { message: { content: "Hello!" } } ]
      }.to_json)

    assert_equal "Hello!", @client.complete("gpt-4o-mini", "Hi")
  end
end
