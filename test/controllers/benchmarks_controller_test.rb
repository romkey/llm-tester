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
end
