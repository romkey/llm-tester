# frozen_string_literal: true

require "test_helper"

class TestRunsControllerTest < ActionDispatch::IntegrationTest
  test "index lists recent runs" do
    get test_runs_url
    assert_response :success
    assert_select "td", test_runs(:passed_run).test_definition.name
  end

  test "show displays run details" do
    run = test_runs(:failed_run)
    get test_run_url(run)
    assert_response :success
    assert_select "pre", run.actual_response
  end
end
