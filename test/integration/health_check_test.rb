# frozen_string_literal: true

require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "health check returns success" do
    get rails_health_check_url
    assert_response :success
  end
end
