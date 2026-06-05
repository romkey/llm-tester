# frozen_string_literal: true

require "test_helper"

class FooterTest < ActionDispatch::IntegrationTest
  test "footer shows version and github link" do
    ENV["APP_VERSION"] = "v9.9.9"
    ENV["GITHUB_REPO_URL"] = "https://github.com/romkey/llm-tester"

    get root_url
    assert_response :success
    assert_select "footer", /Version v9\.9\.9/
    assert_select "footer a[href=?]", "https://github.com/romkey/llm-tester", text: "romkey/llm-tester"
  ensure
    ENV.delete("APP_VERSION")
    ENV.delete("GITHUB_REPO_URL")
  end
end
