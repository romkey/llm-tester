# frozen_string_literal: true

require "test_helper"

class BenchmarksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "index shows latest benchmark comparison" do
    get benchmarks_url
    assert_response :success
    assert_select "h1", "Benchmarks"
    assert_select "td", text: llm_models(:llama).name
    assert_select "td", text: llm_models(:gpt).name
  end

  test "run_now queues benchmarks and redirects" do
    assert_enqueued_with(job: RunScheduledBenchmarksJob) do
      post run_now_benchmarks_url
    end

    assert_redirected_to benchmarks_path
    follow_redirect!
    assert_select ".alert", /Benchmarks queued/
  end

  test "run_now warns when no models are enabled" do
    LlmModel.update_all(enabled: false)

    assert_no_enqueued_jobs only: RunScheduledBenchmarksJob do
      post run_now_benchmarks_url
    end

    assert_redirected_to benchmarks_path
    follow_redirect!
    assert_select ".alert", /No enabled models/
  end

  test "show displays benchmark run details" do
    get benchmark_url(benchmark_runs(:llama_latest))

    assert_response :success
    assert_select "h1", "Benchmark Run"
  end

  test "show surfaces the error message, command, and output" do
    model = llm_models(:llama)
    run = BenchmarkRun.create!(
      llm_model: model,
      server: model.server,
      status: "error",
      error_message: "Could not reach Ollama server: Connection refused",
      command: "llama-benchy --model llama3 --api-key [REDACTED]",
      output: "traceback details",
      started_at: Time.current,
      finished_at: Time.current
    )

    get benchmark_url(run)

    assert_response :success
    assert_select ".alert", /Could not reach Ollama server/
    assert_select "pre", text: /llama-benchy --model llama3/
    assert_select "pre", text: /traceback details/
  end
end
