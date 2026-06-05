# frozen_string_literal: true

require "test_helper"

module Settings
  class ServersControllerTest < ActionDispatch::IntegrationTest
    test "create server and sync models" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: { models: [ { name: "auto-model" } ] }.to_json)

      assert_difference "Server.count", 1 do
        post settings_servers_url, params: {
          server: {
            name: "New Ollama",
            hostname: "localhost:11434",
            api_type: "ollama"
          }
        }
      end

      server = Server.find_by!(name: "New Ollama")
      assert server.llm_models.exists?(name: "auto-model")
      assert_redirected_to settings_servers_url
    end

    test "update server" do
      server = servers(:ollama)
      patch settings_server_url(server), params: {
        server: { name: "Renamed Ollama", hostname: server.hostname, api_type: server.api_type }
      }

      assert_redirected_to settings_servers_url
      assert_equal "Renamed Ollama", server.reload.name
    end

    test "destroy server" do
      server = Server.create!(name: "Temp", hostname: "temp.local", api_type: "ollama")

      assert_difference "Server.count", -1 do
        delete settings_server_url(server)
      end

      assert_redirected_to settings_servers_url
    end
  end
end
