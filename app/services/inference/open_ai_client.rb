# frozen_string_literal: true

module Inference
  class OpenAiClient < Client
    def list_models
      response = get("/v1/models")
      response.fetch("data", []).map { |model| model.fetch("id") }
    end

    def complete(model_name, prompt)
      started_at = Time.current
      response = post("/v1/chat/completions", {
        model: model_name,
        messages: [ { role: "user", content: prompt } ]
      })

      usage = response["usage"] || {}
      CompletionResult.from_timed(
        started_at: started_at,
        text: response.dig("choices", 0, "message", "content").to_s,
        prompt_tokens: usage["prompt_tokens"],
        completion_tokens: usage["completion_tokens"]
      )
    end

    private

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
      request["Authorization"] = "Bearer #{api_key}" if api_key.present?
      request.body = body.to_json if body

      response = http.request(request)
      raise Error, "OpenAI request failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid OpenAI response: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      raise Error, "Could not reach OpenAI server: #{e.message}"
    end
  end
end
