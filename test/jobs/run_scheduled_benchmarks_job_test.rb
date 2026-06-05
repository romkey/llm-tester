# frozen_string_literal: true

require "test_helper"

class RunScheduledBenchmarksJobTest < ActiveJob::TestCase
  test "enqueues benchmark job for each enabled model" do
    assert_enqueued_jobs LlmModel.enabled.count, only: RunModelBenchmarkJob do
      RunScheduledBenchmarksJob.perform_now
    end
  end
end
