# frozen_string_literal: true

require "test_helper"

class ServersControllerTest < ActionDispatch::IntegrationTest
  test "index shows servers dashboard" do
    get root_url
    assert_response :success
    assert_select "h1", "Servers"
    assert_select "strong", servers(:ollama).name
  end

  test "sync_models creates remote models" do
    stub_request(:get, "http://localhost:11434/api/tags")
      .to_return(status: 200, body: { models: [ { name: "synced-model" } ] }.to_json)

    assert_difference "LlmModel.count", 1 do
      post sync_models_server_url(servers(:ollama))
    end

    assert_redirected_to root_url
    assert LlmModel.exists?(name: "synced-model")
  end
end
