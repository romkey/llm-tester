# frozen_string_literal: true

class RunScheduledBenchmarksJob < ApplicationJob
  queue_as :default

  def perform
    LlmModel.enabled.find_each do |model|
      RunModelBenchmarkJob.perform_later(model.id)
    end
  end
end
