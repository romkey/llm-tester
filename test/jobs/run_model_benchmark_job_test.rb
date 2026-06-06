# frozen_string_literal: true

require "test_helper"

class RunModelBenchmarkJobTest < ActiveJob::TestCase
  test "does not benchmark disabled models" do
    model = llm_models(:disabled_model)

    assert_no_difference "BenchmarkRun.count" do
      RunModelBenchmarkJob.perform_now(model.id)
    end
  end

  test "records a benchmark run for enabled models" do
    model = llm_models(:llama)

    assert_difference "BenchmarkRun.count", 1 do
      RunModelBenchmarkJob.perform_now(model.id)
    end
  end

  test "uses the model's configured benchmark latency mode" do
    model = llm_models(:llama)
    model.update!(benchmark_latency_mode: "none")

    RunModelBenchmarkJob.perform_now(model.id)

    run = model.benchmark_runs.order(:created_at).last
    assert_includes run.command, "--latency-mode none"
  end
end
