# frozen_string_literal: true

require "test_helper"

class RunTestJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  test "runs inference test for definition" do
    definition = test_definitions(:exact_greeting)

    stub_request(:post, "http://localhost:11434/api/generate")
      .to_return(status: 200, body: { response: "Hello!" }.to_json)

    assert_difference "TestRun.count", 1 do
      perform_enqueued_jobs do
        RunTestJob.perform_later(definition.id)
      end
    end
  end
end
