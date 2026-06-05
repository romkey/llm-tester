# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Inference
  class OllamaClient < Client
    def list_models
      response = get("/api/tags")
      models = response.fetch("models", [])
      models.map { |model| model.fetch("name") }
    end

    def complete(model_name, prompt)
      response = post("/api/generate", {
        model: model_name,
        prompt: prompt,
        stream: false
      })
      response.fetch("response")
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
