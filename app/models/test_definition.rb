# frozen_string_literal: true

class TestDefinition < ApplicationRecord
  RESPONSE_TYPES = %w[exact approximate any].freeze
  ALLOWED_IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_IMAGE_SIZE = 10.megabytes

  belongs_to :llm_model, optional: true
  has_many :test_runs, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true
  validates :prompt, presence: true
  validates :response_type, presence: true, inclusion: { in: RESPONSE_TYPES }
  validates :frequency_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :expected_response, presence: true, if: -> { exact? }
  validates :regex_pattern, presence: true, if: -> { approximate? }
  validates :llm_model, presence: true, unless: :run_on_all_models?
  validate :regex_pattern_must_be_valid, if: -> { approximate? && regex_pattern.present? }
  validate :llm_model_must_be_blank_for_all_models
  validate :acceptable_image

  before_validation :clear_llm_model_when_running_on_all_models

  scope :enabled, -> { where(enabled: true) }
  scope :for_model, lambda { |model|
    enabled.where(run_on_all_models: true).or(enabled.where(llm_model: model))
  }

  def self.due_for_run
    enabled.find_each.select(&:due_for_run?)
  end

  def target_models
    if run_on_all_models?
      LlmModel.enabled.includes(:server).order("servers.name ASC", "llm_models.name ASC")
    else
      LlmModel.enabled.where(id: llm_model_id)
    end
  end

  def model_label
    run_on_all_models? ? "All models" : llm_model.label_with_server
  end

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

  def latest_run_for(model)
    test_runs.where(llm_model: model).order(created_at: :desc).first
  end

  def passed_for_model?(model)
    latest_run_for(model)&.passed?
  end

  private

  def clear_llm_model_when_running_on_all_models
    self.llm_model = nil if run_on_all_models?
  end

  def llm_model_must_be_blank_for_all_models
    return unless run_on_all_models? && llm_model_id.present?

    errors.add(:llm_model, "must be blank when running on all models")
  end

  def regex_pattern_must_be_valid
    Regexp.new(regex_pattern)
  rescue RegexpError => e
    errors.add(:regex_pattern, "is invalid: #{e.message}")
  end

  def acceptable_image
    return unless image.attached?

    unless image.content_type.in?(ALLOWED_IMAGE_CONTENT_TYPES)
      errors.add(:image, "must be a PNG, JPEG, GIF, or WebP file")
    end

    return unless image.byte_size > MAX_IMAGE_SIZE

    errors.add(:image, "must be less than 10 MB")
  end
end
