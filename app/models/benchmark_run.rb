# frozen_string_literal: true

class BenchmarkRun < ApplicationRecord
  STATUSES = %w[passed error].freeze

  belongs_to :llm_model
  belongs_to :server

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }

  def self.latest_per_model
    joins(
      <<~SQL.squish
        INNER JOIN (
          SELECT llm_model_id, MAX(created_at) AS latest_created_at
          FROM benchmark_runs
          GROUP BY llm_model_id
        ) latest ON latest.llm_model_id = benchmark_runs.llm_model_id
        AND latest.latest_created_at = benchmark_runs.created_at
      SQL
    ).includes(llm_model: :server).order("servers.name ASC", "llm_models.name ASC")
  end

  def passed?
    status == "passed"
  end

  def error?
    status == "error"
  end
end
