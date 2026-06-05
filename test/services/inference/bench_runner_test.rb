# frozen_string_literal: true

require "test_helper"

class InferenceBenchRunnerTest < ActiveSupport::TestCase
  REPORT_PATH = Rails.root.join("test/fixtures/files/bench_report.json")

  FakeBenchCommand = Class.new do
    def self.run(model:, output_path:, **)
      File.write(output_path, File.read(InferenceBenchRunnerTest::REPORT_PATH))
    end
  end

  test "records passed benchmark run" do
    model = llm_models(:llama)

    assert_difference "BenchmarkRun.count", 1 do
      run = Inference::BenchRunner.run(model, command: FakeBenchCommand)
      assert run.passed?
      assert_in_delta 1234.5, run.prompt_tokens_per_second
      assert_in_delta 56.7, run.generation_tokens_per_second
      assert run.raw_report.present?
    end
  end

  test "records error when command fails" do
    model = llm_models(:llama)
    failing_command = Class.new do
      def self.run(**)
        raise Inference::BenchCommand::Error, "bench failed"
      end
    end

    run = Inference::BenchRunner.run(model, command: failing_command)
    assert run.error?
    assert_equal "bench failed", run.error_message
  end
end
