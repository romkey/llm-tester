# frozen_string_literal: true

module ApplicationHelper
  def health_badge(status)
    case status.to_sym
    when :healthy
      tag.span("Healthy", class: "badge text-bg-success")
    when :unhealthy
      tag.span("Unhealthy", class: "badge text-bg-danger")
    else
      tag.span("Unknown", class: "badge text-bg-secondary")
    end
  end

  def test_run_badge(test_run)
    if test_run.passed?
      tag.span("Passed", class: "badge text-bg-success")
    elsif test_run.failed?
      tag.span("Failed", class: "badge text-bg-danger")
    else
      tag.span("Error", class: "badge text-bg-warning")
    end
  end

  def app_version
    AppVersion.current
  end

  def github_repo_url
    AppVersion.github_repo_url
  end

  def github_repo_label
    AppVersion.github_repo_label
  end

  def pagy_nav(pagy)
    pagy.series_nav if pagy.pages > 1
  end
end
