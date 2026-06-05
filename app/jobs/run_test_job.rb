# frozen_string_literal: true

class RunTestJob < ApplicationJob
  queue_as :default

  def perform(test_definition_id)
    definition = TestDefinition.find(test_definition_id)
    Inference::TestRunner.run(definition)
  end
end
