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

  test "complete sends multimodal content when images provided" do
    image = Inference::ImageEncoder::EncodedImage.new(base64: "abc123", content_type: "image/png")

    stub_request(:post, "https://api.example.com/v1/chat/completions")
      .with { |request|
        body = JSON.parse(request.body)
        content = body.dig("messages", 0, "content")
        content.is_a?(Array) &&
          content.any? { |part| part["type"] == "text" && part["text"] == "What is this?" } &&
          content.any? { |part|
            part["type"] == "image_url" &&
              part.dig("image_url", "url") == "data:image/png;base64,abc123"
          }
      }
      .to_return(status: 200, body: {
        choices: [ { message: { content: "A pixel" } } ],
        usage: { prompt_tokens: 20, completion_tokens: 3 }
      }.to_json)

    result = Inference::OpenAiClient.new(servers(:openai)).complete("gpt-4o", "What is this?", images: [ image ])
    assert_equal "A pixel", result.text
  end
end
