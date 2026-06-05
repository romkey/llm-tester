# frozen_string_literal: true

require "test_helper"

class InferenceBenchReportParserTest < ActiveSupport::TestCase
  test "extracts summary metrics from report" do
    report = JSON.parse(file_fixture("bench_report.json").read)
    summary = Inference::BenchReportParser.summary(report)

    assert_equal 512, summary[:prompt_tokens]
    assert_equal 32, summary[:generation_tokens]
    assert_in_delta 1234.5, summary[:prompt_tokens_per_second]
    assert_in_delta 56.7, summary[:generation_tokens_per_second]
    assert_in_delta 58.2, summary[:peak_generation_tokens_per_second]
    assert_in_delta 420.5, summary[:time_to_first_token_ms]
    assert_in_delta 380.2, summary[:estimated_prompt_processing_ms]
  end
end
