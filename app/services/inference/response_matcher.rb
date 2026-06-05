# frozen_string_literal: true

module Inference
  class ResponseMatcher
    def self.match?(definition, actual_response)
      new(definition, actual_response).match?
    end

    def initialize(definition, actual_response)
      @definition = definition
      @actual_response = actual_response.to_s
    end

    def match?
      case definition.response_type
      when "exact"
        actual_response.strip == definition.expected_response.to_s.strip
      when "approximate"
        Regexp.new(definition.regex_pattern).match?(actual_response)
      when "any"
        actual_response.present?
      else
        false
      end
    end

    private

    attr_reader :definition, :actual_response
  end
end
