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

      Tempfile.create([ "benchmark", ".json" ]) do |file|
        file.close
        @command.run(model: @model, output_path: file.path, **@options)
        report = JSON.parse(File.read(file.path))
        summary = BenchReportParser.summary(report)

        BenchmarkRun.create!(
          benchmark_attributes(
            started_at: started_at,
            status: "passed",
            raw_report: report.to_json,
            **summary
          )
        )
      end
    rescue BenchCommand::Error, JSON::ParserError, Errno::ENOENT => e
      BenchmarkRun.create!(
        benchmark_attributes(
          started_at: started_at,
          status: "error",
          error_message: e.message,
          finished_at: Time.current
        )
      )
    end

    private

    attr_reader :model

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
