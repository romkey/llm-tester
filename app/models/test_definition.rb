# frozen_string_literal: true

class TestDefinition < ApplicationRecord
  RESPONSE_TYPES = %w[exact approximate any].freeze

  belongs_to :llm_model
  has_many :test_runs, dependent: :destroy

  validates :name, presence: true
  validates :prompt, presence: true
  validates :response_type, presence: true, inclusion: { in: RESPONSE_TYPES }
  validates :frequency_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :expected_response, presence: true, if: -> { exact? }
  validates :regex_pattern, presence: true, if: -> { approximate? }
  validate :regex_pattern_must_be_valid, if: -> { approximate? && regex_pattern.present? }

  scope :enabled, -> { where(enabled: true) }

  def self.due_for_run
    enabled.find_each.select(&:due_for_run?)
  end

  delegate :server, to: :llm_model

  def exact?
    response_type == "exact"
  end

  def approximate?
    response_type == "approximate"
  end

  def any?
    response_type == "any"
  end

  def due_for_run?
    return false unless enabled?

    last_run_at.nil? || last_run_at <= frequency_minutes.minutes.ago
  end

  def latest_run
    test_runs.order(created_at: :desc).first
  end

  private

  def regex_pattern_must_be_valid
    Regexp.new(regex_pattern)
  rescue RegexpError => e
    errors.add(:regex_pattern, "is invalid: #{e.message}")
  end
end
