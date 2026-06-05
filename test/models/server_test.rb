# frozen_string_literal: true

require "test_helper"

class ServerTest < ActiveSupport::TestCase
  test "validates presence and api type" do
    server = Server.new
    assert_not server.valid?
    assert_includes server.errors[:name], "can't be blank"
    assert_includes server.errors[:hostname], "can't be blank"
    assert_includes server.errors[:api_type], "can't be blank"
  end

  test "base_url adds http when missing scheme" do
    server = servers(:ollama)
    assert_equal "http://localhost:11434", server.base_url
  end

  test "base_url preserves explicit scheme" do
    server = servers(:openai)
    assert_equal "https://api.example.com", server.base_url
  end

  test "healthy when all models are healthy" do
    server = servers(:ollama)
    assert server.healthy?
  end

  test "unknown health when no models" do
    server = Server.create!(name: "Empty", hostname: "empty.local", api_type: "ollama")
    assert_equal :unknown, server.health_status
  end

  test "unhealthy when a model fails latest test" do
    server = servers(:ollama)
    test_definitions(:approximate_greeting).test_runs.create!(
      llm_model: llm_models(:llama),
      server: server,
      status: "failed",
      actual_response: "nope",
      started_at: Time.current,
      finished_at: Time.current
    )

    assert_not server.healthy?
    assert_equal :unhealthy, server.health_status
  end

  test "ignores disabled models for health" do
    server = servers(:ollama)
    disabled = llm_models(:disabled_model)

    test_definitions(:exact_greeting).test_runs.create!(
      llm_model: disabled,
      server: server,
      status: "failed",
      actual_response: "nope",
      started_at: Time.current,
      finished_at: Time.current
    )

    assert server.healthy?
  end

  test "unknown health when all models disabled" do
    server = servers(:ollama)
    server.llm_models.update_all(enabled: false)

    assert_equal :unknown, server.health_status
  end
end
