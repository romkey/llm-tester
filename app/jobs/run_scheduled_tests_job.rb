# frozen_string_literal: true

class RunScheduledTestsJob < ApplicationJob
  queue_as :default

  def perform
    TestDefinition.due_for_run.each do |definition|
      RunTestJob.perform_later(definition.id)
    end
  end
end
