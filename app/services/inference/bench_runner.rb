# frozen_string_literal: true

module Inference
  class BenchRunner
    DEFAULT_OPTIONS = {
      pp: 512,
      tg: 32,
      depth: 0,
      runs: 1,
      latency_mode: "generation",
      adapt_prompt: true
    }.freeze

    def self.run(model, command: BenchCommand, **options)
      new(model, command: command, **DEFAULT_OPTIONS.merge(options)).run
    end

    def initialize(model, command:, **options)
      @model = model
      @command = command
      @options = options
    end

    def run
      started_at = Time.current
      command = nil
      output = nil

      Tempfile.create([ "benchmark", ".json" ]) do |file|
        file.close
        result = @command.run(model: @model, output_path: file.path, **@options)
        command = result.command
        output = combine_output(result.stdout, result.stderr)
        report = JSON.parse(File.read(file.path))

        unless BenchReportParser.usable?(report)
          next record_error(
            started_at,
            benchmark_failure_message(output),
            command: command,
            output: output,
            raw_report: report.to_json
          )
        end

        summary = BenchReportParser.summary(report)

        BenchmarkRun.create!(
          benchmark_attributes(
            started_at: started_at,
            status: "passed",
            command: command,
            output: output,
            raw_report: report.to_json,
            **summary
          )
        )
      end
    rescue BenchCommand::Error => e
      record_error(started_at, e.message, command: e.command, output: combine_output(e.stdout, e.stderr))
    rescue StandardError => e
      # Record every other failure (parse errors, missing binary, unexpected
      # exceptions, etc.) so it is visible in the UI instead of only surfacing
      # as a silent Sidekiq retry.
      record_error(started_at, "#{e.class}: #{e.message}", command: command, output: output)
    end

    private

    attr_reader :model

    def record_error(started_at, message, command:, output:, raw_report: nil)
      BenchmarkRun.create!(
        benchmark_attributes(
          started_at: started_at,
          status: "error",
          error_message: message,
          command: command,
          output: output,
          raw_report: raw_report,
          finished_at: Time.current
        )
      )
    end

    # llama-benchy writes a result file with null metrics when the model server
    # errors mid-run. Surface the underlying HTTP error from the output when we
    # can find it so the failure is actionable in the UI.
    def benchmark_failure_message(output)
      base = "Benchmark produced no throughput data; the model server likely returned an error."
      http_line = output.to_s.lines.find { |line| line.match?(/HTTP \d{3}/) }
      return base unless http_line

      "#{base} #{http_line.strip.truncate(300)}"
    end

    def combine_output(stdout, stderr)
      [ stdout, stderr ].compact_blank.join("\n\n").presence
    end

    def benchmark_attributes(started_at:, status:, finished_at: Time.current, **attributes)
      {
        llm_model: model,
        server: model.server,
        status: status,
        started_at: started_at,
        finished_at: finished_at,
        **attributes
      }
    end
  end
end
