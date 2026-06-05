# frozen_string_literal: true

module AppVersion
  module_function

  def current
    from_env || from_git || "dev"
  end

  def github_repo_url
    ENV["GITHUB_REPO_URL"].presence || from_git_remote
  end

  def github_repo_label
    url = github_repo_url
    return unless url

    url.delete_prefix("https://github.com/").delete_suffix(".git")
  end

  def from_env
    ENV["APP_VERSION"].presence
  end

  def from_git
    return unless git_available?

    exact_tag = `git describe --tags --exact-match 2>/dev/null`.strip
    return exact_tag if exact_tag.present?

    describe = `git describe --tags --always 2>/dev/null`.strip
    describe.presence
  end

  def from_git_remote
    return unless git_available?

    remote = `git remote get-url origin 2>/dev/null`.strip
    return if remote.blank?

    parse_github_remote(remote)
  end

  def parse_github_remote(remote)
    if remote.start_with?("git@github.com:")
      "https://github.com/#{remote.delete_prefix("git@github.com:").delete_suffix(".git")}"
    elsif remote.include?("github.com")
      uri = remote.sub(%r{\Agit://}, "https://").sub(%r{\.git\z}, "")
      uri.start_with?("http") ? uri : "https://#{uri}"
    end
  end

  def git_available?
    system("git rev-parse --is-inside-work-tree >/dev/null 2>&1")
  end
  private_class_method :git_available?
end
