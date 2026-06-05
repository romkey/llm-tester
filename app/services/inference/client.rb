# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Inference
  class Error < StandardError; end

  class Client
    def self.for(server)
      case server.api_type
      when "ollama" then OllamaClient.new(server)
      when "openai" then OpenAiClient.new(server)
      else
        raise Error, "Unsupported API type: #{server.api_type}"
      end
    end

    def initialize(server)
      @server = server
    end

    def list_models
      raise NotImplementedError
    end

    def complete(model_name, prompt, images: [])
      raise NotImplementedError
    end

    private

    attr_reader :server

    def base_url
      server.base_url
    end

    def api_key
      server.api_key
    end
  end
end
