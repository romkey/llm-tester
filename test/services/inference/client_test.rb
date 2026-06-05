# frozen_string_literal: true

require "test_helper"
require "open3"

class InferenceClientTest < ActiveSupport::TestCase
  test "client.rb explicitly requires net/http stdlib" do
    root = Rails.root.to_s
    script = <<~RUBY
      root = #{root.inspect}
      features_before = $LOADED_FEATURES.dup
      load File.join(root, "app/services/inference/client.rb")
      newly_loaded = ($LOADED_FEATURES - features_before).grep(%r{net/http})
      raise "net/http was not required" if newly_loaded.empty?
      raise "Net::HTTP is unavailable" unless defined?(Net::HTTP)
      print "ok"
    RUBY

    output, status = Open3.capture2(RbConfig.ruby, "-e", script)
    assert status.success?, "expected subprocess success, got: #{output}"
    assert_equal "ok", output
  end

  test "open ai client can list models without NameError" do
    stub_request(:get, "https://api.example.com/v1/models")
      .to_return(status: 200, body: { data: [ { id: "gpt-4o" } ] }.to_json)

    models = Inference::OpenAiClient.new(servers(:openai)).list_models
    assert_equal [ "gpt-4o" ], models
  end
end
