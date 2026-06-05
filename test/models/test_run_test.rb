# frozen_string_literal: true

require "test_helper"

class TestRunTest < ActiveSupport::TestCase
  test "status helpers" do
    run = test_runs(:passed_run)
    assert run.passed?
    assert run.succeeded?
    assert_not run.failed?

    failed = test_runs(:failed_run)
    assert failed.failed?
    assert_not failed.passed?
  end
end
