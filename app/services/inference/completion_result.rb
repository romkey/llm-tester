# frozen_string_literal: true

module Inference
  CompletionResult = Data.define(
    :text,
    :latency_ms,
    :tokens_per_second,
    :prompt_tokens,
    :completion_tokens
  ) do
    def self.from_timed(started_at:, text:, prompt_tokens: nil, completion_tokens: nil, server_duration_ms: nil)
      latency_ms = ((Time.current - started_at) * 1000).round(1)
      tokens_per_second = compute_tokens_per_second(
        completion_tokens: completion_tokens,
        latency_ms: server_duration_ms || latency_ms
      )

      new(
        text: text,
        latency_ms: latency_ms,
        tokens_per_second: tokens_per_second,
        prompt_tokens: prompt_tokens,
        completion_tokens: completion_tokens
      )
    end

    def self.compute_tokens_per_second(completion_tokens:, latency_ms:)
      return if completion_tokens.nil? || latency_ms.nil? || latency_ms <= 0

      (completion_tokens / (latency_ms / 1000.0)).round(2)
    end
  end
end
