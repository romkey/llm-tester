# frozen_string_literal: true

require "test_helper"

class AppVersionTest < ActiveSupport::TestCase
  test "current reads VERSION file" do
    assert_equal File.read(AppVersion::VERSION_FILE).strip, AppVersion.current
  end

  test "github_repo_url reads config/github_repository" do
    assert_equal "https://github.com/romkey/llm-tester", AppVersion.github_repo_url
    assert_equal "romkey/llm-tester", AppVersion.github_repo_label
  end

  test "parse_github_remote_slug handles ssh remotes" do
    assert_equal "romkey/llm-tester",
      AppVersion.parse_github_remote_slug("git@github.com:romkey/llm-tester.git")
  end

  test "parse_github_remote_slug handles https remotes" do
    assert_equal "romkey/llm-tester",
      AppVersion.parse_github_remote_slug("https://github.com/romkey/llm-tester.git")
  end

  test "from_git returns a value in a git checkout" do
    skip "Not a git repository" unless AppVersion.send(:git_available?)

    assert AppVersion.from_git.present?
  end
end
