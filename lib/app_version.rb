# frozen_string_literal: true

module AppVersion
  ROOT = File.expand_path("..", __dir__)
  VERSION_FILE = File.join(ROOT, "VERSION")
  REPOSITORY_FILE = File.join(ROOT, "config", "github_repository")

  module_function

  def current
    from_version_file || from_git || "dev"
  end

  def github_repo_url
    slug = github_repo_slug
    return unless slug

    "https://github.com/#{slug}"
  end

  def github_repo_label
    github_repo_slug
  end

  def github_repo_slug
    from_repository_file || from_git_remote_slug
  end

  def from_version_file
    read_file(VERSION_FILE)
  end

  def from_repository_file
    read_file(REPOSITORY_FILE)
  end

  def from_git
    return unless git_available?

    exact_tag = `git describe --tags --exact-match 2>/dev/null`.strip
    return exact_tag if exact_tag.present?

    describe = `git describe --tags --always 2>/dev/null`.strip
    describe.presence
  end

  def from_git_remote_slug
    return unless git_available?

    remote = `git remote get-url origin 2>/dev/null`.strip
    return if remote.blank?

    parse_github_remote_slug(remote)
  end

  def parse_github_remote_slug(remote)
    if remote.start_with?("git@github.com:")
      remote.delete_prefix("git@github.com:").delete_suffix(".git")
    elsif remote.include?("github.com")
      remote.sub(%r{\Agit://}, "https://")
          .sub(%r{\Ahttps?://github\.com/}, "")
          .delete_suffix(".git")
          .presence
    end
  end

  def read_file(path)
    return unless File.file?(path)

    File.read(path).strip.presence
  end

  def git_available?
    system("git rev-parse --is-inside-work-tree >/dev/null 2>&1")
  end
  private_class_method :git_available?
end
