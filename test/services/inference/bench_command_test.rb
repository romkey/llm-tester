# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class InferenceBenchCommandTest < ActiveSupport::TestCase
  Status = Struct.new(:success?, :exitstatus)

  def run_command(model:, output_path:, capture:)
    Inference::BenchCommand.run(
      model: model,
      output_path: output_path,
      pp: 512,
      tg: 32,
      depth: 0,
      runs: 1,
      latency_mode: "generation",
      capture: capture
    )
  end

  test "runs llama-benchy with a keyword model argument" do
    model = llm_models(:llama)

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      captured_command = nil

      capture = lambda do |*command|
        captured_command = command
        File.write(output_path, "{}")
        [ "out", "", Status.new(true, 0) ]
      end

      assert_nil run_command(model: model, output_path: output_path, capture: capture)

      assert_equal "llama-benchy", captured_command.first
      assert_includes captured_command, model.name
      assert_includes captured_command, output_path
    end
  end

  test "raises BenchCommand::Error with a keyword model argument when the process fails" do
    model = llm_models(:llama)

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      capture = ->(*_command) { [ "", "boom", Status.new(false, 1) ] }

      error = assert_raises(Inference::BenchCommand::Error) do
        run_command(model: model, output_path: output_path, capture: capture)
      end
      assert_equal "boom", error.message
    end
  end
end
