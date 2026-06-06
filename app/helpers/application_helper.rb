# frozen_string_literal: true

module ApplicationHelper
  def health_badge(status)
    case status.to_sym
    when :healthy
      tag.span("Healthy", class: "badge text-bg-success")
    when :unhealthy
      tag.span("Unhealthy", class: "badge text-bg-danger")
    when :disabled
      tag.span("Disabled", class: "badge text-bg-secondary")
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

  def benchmark_status_badge(benchmark_run)
    if benchmark_run.passed?
      tag.span("Passed", class: "badge text-bg-success")
    else
      tag.span("Error", class: "badge text-bg-warning")
    end
  end

  def test_run_reason(test_run)
    return "Test has not been run yet." if test_run.nil?
    return "Passed." if test_run.passed?
    return test_run.error_message.presence || "Request failed before a response was received." if test_run.error?

    "Response did not match the expected result."
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

  def format_ms(value)
    return "—" if value.nil?

    "#{number_with_precision(value, precision: 1, delimiter: ',')} ms"
  end

  def format_tokens_per_second(value)
    return "—" if value.nil?

    "#{number_with_precision(value, precision: 1, delimiter: ',')} t/s"
  end
end
