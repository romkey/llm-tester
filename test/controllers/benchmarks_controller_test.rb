# frozen_string_literal: true

require "test_helper"

class BenchmarksControllerTest < ActionDispatch::IntegrationTest
  test "index shows latest benchmark comparison" do
    get benchmarks_url
    assert_response :success
    assert_select "h1", "Benchmarks"
    assert_select "td", text: llm_models(:llama).name
    assert_select "td", text: llm_models(:gpt).name
  end
end
