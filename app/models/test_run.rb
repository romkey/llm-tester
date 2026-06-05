# frozen_string_literal: true

class TestRun < ApplicationRecord
  STATUSES = %w[passed failed error].freeze

  belongs_to :test_definition
  belongs_to :llm_model
  belongs_to :server

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }

  def passed?
    status == "passed"
  end

  def failed?
    status == "failed"
  end

  def error?
    status == "error"
  end

  def succeeded?
    passed?
  end
end
