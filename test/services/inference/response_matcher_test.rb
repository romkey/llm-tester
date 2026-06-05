# frozen_string_literal: true

require "test_helper"

class InferenceResponseMatcherTest < ActiveSupport::TestCase
  test "exact match compares stripped strings" do
    definition = test_definitions(:exact_greeting)
    assert Inference::ResponseMatcher.match?(definition, "  Hello!  ")
    assert_not Inference::ResponseMatcher.match?(definition, "Hello")
  end

  test "approximate match uses regex" do
    definition = test_definitions(:approximate_greeting)
    assert Inference::ResponseMatcher.match?(definition, "Well hello there")
    assert_not Inference::ResponseMatcher.match?(definition, "goodbye")
  end

  test "any match requires non-empty response" do
    definition = test_definitions(:any_response)
    assert Inference::ResponseMatcher.match?(definition, "anything")
    assert_not Inference::ResponseMatcher.match?(definition, "")
  end
end
