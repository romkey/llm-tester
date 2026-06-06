# frozen_string_literal: true

require "test_helper"

class TestRunsControllerTest < ActionDispatch::IntegrationTest
  test "index lists recent runs" do
    get test_runs_url
    assert_response :success
    assert_select "td", test_runs(:passed_run).test_definition.name
  end

  test "filters runs by test definition" do
    get test_runs_url(test_definition_id: test_definitions(:exact_greeting).id)

    assert_response :success
    assert_select "td", text: "Exact greeting"
    assert_select "td", text: "Approximate greeting", count: 0
    assert_select "td", text: "Any response", count: 0
  end

  test "filters runs by model" do
    get test_runs_url(llm_model_id: llm_models(:gpt).id)

    assert_response :success
    assert_select "td", text: "gpt-4o-mini"
    assert_select "td", text: "llama3", count: 0
  end

  test "filters runs by result status" do
    get test_runs_url(status: "failed")

    assert_response :success
    assert_select "span.badge", text: "Failed"
    assert_select "span.badge", text: "Passed", count: 0
  end

  test "ignores an unrecognized status filter" do
    get test_runs_url(status: "bogus")

    assert_response :success
    assert_select "td", text: test_runs(:passed_run).test_definition.name
  end

  test "shows a filter-specific empty message when nothing matches" do
    TestRun.delete_all

    get test_runs_url(test_definition_id: test_definitions(:exact_greeting).id)

    assert_response :success
    assert_select "p", text: "No test runs match these filters."
  end

  test "show displays run details" do
    run = test_runs(:failed_run)
    get test_run_url(run)
    assert_response :success
    assert_select "pre", run.actual_response
  end
end
