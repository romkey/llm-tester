# frozen_string_literal: true

require "test_helper"

class BenchmarkRunTest < ActiveSupport::TestCase
  test "latest_per_model returns most recent run for each model" do
    latest = BenchmarkRun.latest_per_model

    assert_includes latest, benchmark_runs(:llama_latest)
    assert_includes latest, benchmark_runs(:gpt_latest)
    assert_not_includes latest, benchmark_runs(:llama_old)
  end
end
