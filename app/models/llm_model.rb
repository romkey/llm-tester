# frozen_string_literal: true

class LlmModel < ApplicationRecord
  belongs_to :server
  has_many :test_definitions, dependent: :destroy
  has_many :test_runs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :server_id }

  def label_with_server
    "#{name} (#{server.name})"
  end

  def healthy?
    enabled_test_definitions = test_definitions.where(enabled: true)
    return true if enabled_test_definitions.none?

    enabled_test_definitions.all? do |definition|
      definition.latest_run&.passed?
    end
  end

  def health_status
    return :unknown if test_definitions.where(enabled: true).none?

    healthy? ? :healthy : :unhealthy
  end
end
