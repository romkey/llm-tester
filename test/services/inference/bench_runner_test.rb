# frozen_string_literal: true

require "test_helper"

class InferenceBenchRunnerTest < ActiveSupport::TestCase
  REPORT_PATH = Rails.root.join("test/fixtures/files/bench_report.json")

  FakeBenchCommand = Class.new do
    def self.run(model:, output_path:, **)
      File.write(output_path, File.read(InferenceBenchRunnerTest::REPORT_PATH))
      Inference::BenchCommand::Result.new(
        command: "llama-benchy --model #{model.name}",
        stdout: "benchmark complete",
        stderr: ""
      )
    end
  end

  test "records passed benchmark run with command and output" do
    model = llm_models(:llama)

    assert_difference "BenchmarkRun.count", 1 do
      run = Inference::BenchRunner.run(model, command: FakeBenchCommand)
      assert run.passed?
      assert_in_delta 1234.5, run.prompt_tokens_per_second
      assert_in_delta 56.7, run.generation_tokens_per_second
      assert run.raw_report.present?
      assert_equal "llama-benchy --model #{model.name}", run.command
      assert_equal "benchmark complete", run.output
    end
  end

  test "records error with command and output when command fails" do
    model = llm_models(:llama)
    failing_command = Class.new do
      def self.run(**)
        raise Inference::BenchCommand::Error.new(
          "bench failed",
          command: "llama-benchy --model boom",
          stdout: "partial",
          stderr: "boom details"
        )
      end
    end

    run = Inference::BenchRunner.run(model, command: failing_command)
    assert run.error?
    assert_equal "bench failed", run.error_message
    assert_equal "llama-benchy --model boom", run.command
    assert_includes run.output, "boom details"
  end
end
