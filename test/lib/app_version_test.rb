# frozen_string_literal: true

require "test_helper"

class AppVersionTest < ActiveSupport::TestCase
  setup do
    @original_version = ENV["APP_VERSION"]
    @original_repo_url = ENV["GITHUB_REPO_URL"]
    ENV.delete("APP_VERSION")
    ENV.delete("GITHUB_REPO_URL")
  end

  teardown do
    if @original_version
      ENV["APP_VERSION"] = @original_version
    else
      ENV.delete("APP_VERSION")
    end

    if @original_repo_url
      ENV["GITHUB_REPO_URL"] = @original_repo_url
    else
      ENV.delete("GITHUB_REPO_URL")
    end
  end

  test "current prefers APP_VERSION env" do
    ENV["APP_VERSION"] = "v1.2.3"
    assert_equal "v1.2.3", AppVersion.current
  end

  test "github_repo_url prefers env" do
    ENV["GITHUB_REPO_URL"] = "https://github.com/romkey/llm-tester"
    assert_equal "https://github.com/romkey/llm-tester", AppVersion.github_repo_url
    assert_equal "romkey/llm-tester", AppVersion.github_repo_label
  end

  test "parse_github_remote handles ssh remotes" do
    assert_equal "https://github.com/romkey/llm-tester",
      AppVersion.parse_github_remote("git@github.com:romkey/llm-tester.git")
  end

  test "parse_github_remote handles https remotes" do
    assert_equal "https://github.com/romkey/llm-tester",
      AppVersion.parse_github_remote("https://github.com/romkey/llm-tester.git")
  end
end
