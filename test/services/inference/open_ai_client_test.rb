# frozen_string_literal: true

require "test_helper"

class InferenceOpenAiClientTest < ActiveSupport::TestCase
  test "complete records token usage and latency" do
    stub_request(:post, "https://api.example.com/v1/chat/completions")
      .to_return(status: 200, body: {
        choices: [ { message: { content: "Hi there" } } ],
        usage: { prompt_tokens: 12, completion_tokens: 4 }
      }.to_json)

    result = Inference::OpenAiClient.new(servers(:openai)).complete("gpt-4o-mini", "Hello")

    assert_equal "Hi there", result.text
    assert_equal 12, result.prompt_tokens
    assert_equal 4, result.completion_tokens
    assert result.latency_ms.positive?
    assert result.tokens_per_second.positive?
  end
end
