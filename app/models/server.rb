# frozen_string_literal: true

class Server < ApplicationRecord
  API_TYPES = %w[ollama openai].freeze

  has_many :llm_models, dependent: :destroy
  has_many :test_definitions, through: :llm_models
  has_many :test_runs, dependent: :destroy
  has_many :benchmark_runs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :hostname, presence: true
  validates :api_type, presence: true, inclusion: { in: API_TYPES }

  def base_url
    hostname = self.hostname.strip
    return hostname if hostname.match?(%r{\Ahttps?://}i)

    "http://#{hostname}"
  end

  def openai_compatible_base_url
    url = base_url.chomp("/")
    url.end_with?("/v1") ? url : "#{url}/v1"
  end

  def healthy?
    models = llm_models.enabled
    return true if models.none?

    models.all?(&:healthy?)
  end

  def health_status
    return :unknown if llm_models.enabled.none?

    healthy? ? :healthy : :unhealthy
  end
end
