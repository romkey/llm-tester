# frozen_string_literal: true

class LlmModel < ApplicationRecord
  belongs_to :server
  has_many :test_definitions, dependent: :destroy
  has_many :test_runs, dependent: :destroy
  has_many :benchmark_runs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :server_id }

  scope :enabled, -> { where(enabled: true) }

  def self.for_selection(current_id: nil)
    ids = enabled.pluck(:id)
    ids << current_id if current_id.present?
    includes(:server).where(id: ids.compact.uniq).order("servers.name ASC", "llm_models.name ASC")
  end

  def label_with_server
    "#{name} (#{server.name})"
  end

  def applicable_test_definitions
    TestDefinition.enabled.for_model(self)
  end

  def healthy?
    return true unless enabled?

    definitions = applicable_test_definitions
    return true if definitions.none?

    definitions.all? { |definition| definition.passed_for_model?(self) }
  end

  def health_status
    return :disabled unless enabled?
    return :unknown if applicable_test_definitions.none?

    healthy? ? :healthy : :unhealthy
  end
end
