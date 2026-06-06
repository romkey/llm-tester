# frozen_string_literal: true

module Inference
  class BenchRunner
    DEFAULT_OPTIONS = {
      pp: 512,
      tg: 32,
      depth: 0,
      runs: 1,
      latency_mode: "generation"
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
      BenchmarkRun.create!(
        benchmark_attributes(
          started_at: started_at,
          status: "error",
          error_message: e.message,
          command: e.command,
          output: combine_output(e.stdout, e.stderr),
          finished_at: Time.current
        )
      )
    rescue JSON::ParserError, Errno::ENOENT => e
      BenchmarkRun.create!(
        benchmark_attributes(
          started_at: started_at,
          status: "error",
          error_message: e.message,
          command: command,
          output: output,
          finished_at: Time.current
        )
      )
    end

    private

    attr_reader :model

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
