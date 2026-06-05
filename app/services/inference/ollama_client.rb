# frozen_string_literal: true

module Inference
  class OllamaClient < Client
    def list_models
      response = get("/api/tags")
      models = response.fetch("models", [])
      models.map { |model| model.fetch("name") }
    end

    def complete(model_name, prompt, images: [])
      started_at = Time.current
      body = {
        model: model_name,
        prompt: prompt,
        stream: false
      }
      body[:images] = images.map(&:base64) if images.any?

      response = post("/api/generate", body)

      build_completion_result(
        started_at: started_at,
        text: response.fetch("response"),
        prompt_tokens: response["prompt_eval_count"],
        completion_tokens: response["eval_count"],
        generation_duration_ns: response["eval_duration"]
      )
    end

    private

    def build_completion_result(started_at:, text:, prompt_tokens:, completion_tokens:, generation_duration_ns:)
      latency_ms = ((Time.current - started_at) * 1000).round(1)
      tokens_per_second = compute_tokens_per_second(
        completion_tokens: completion_tokens,
        generation_duration_ns: generation_duration_ns
      )

      CompletionResult.new(
        text: text,
        latency_ms: latency_ms,
        tokens_per_second: tokens_per_second,
        prompt_tokens: prompt_tokens,
        completion_tokens: completion_tokens
      )
    end

    def compute_tokens_per_second(completion_tokens:, generation_duration_ns:)
      return unless completion_tokens && generation_duration_ns&.positive?

      (completion_tokens / (generation_duration_ns / 1_000_000_000.0)).round(2)
    end

    def get(path)
      request(:get, path)
    end

    def post(path, body)
      request(:post, path, body)
    end

    def request(method, path, body = nil)
      uri = URI.join(base_url.end_with?("/") ? base_url : "#{base_url}/", path.delete_prefix("/"))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 120

      request_class = method == :get ? Net::HTTP::Get : Net::HTTP::Post
      request = request_class.new(uri)
      request["Content-Type"] = "application/json"
      request.body = body.to_json if body

      response = http.request(request)
      raise Error, "Ollama request failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid Ollama response: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      raise Error, "Could not reach Ollama server: #{e.message}"
    end
  end
end
