# frozen_string_literal: true

require "test_helper"

class RunScheduledTestsJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  test "enqueues due tests" do
    assert_enqueued_jobs TestDefinition.due_for_run.size, only: RunTestJob do
      RunScheduledTestsJob.perform_now
    end
  end
end
