# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class InferenceBenchCommandTest < ActiveSupport::TestCase
  Status = Struct.new(:success?, :exitstatus)

  def run_command(model:, output_path:, capture:, adapt_prompt: true)
    Inference::BenchCommand.run(
      model: model,
      output_path: output_path,
      pp: 512,
      tg: 32,
      depth: 0,
      runs: 1,
      latency_mode: "generation",
      adapt_prompt: adapt_prompt,
      capture: capture
    )
  end

  test "runs llama-benchy with a keyword model argument and returns the command and output" do
    model = llm_models(:llama)

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      captured_command = nil

      capture = lambda do |*command|
        captured_command = command
        File.write(output_path, "{}")
        [ "stdout text", "stderr text", Status.new(true, 0) ]
      end

      result = run_command(model: model, output_path: output_path, capture: capture)

      assert_equal "llama-benchy", captured_command.first
      assert_includes captured_command, model.name
      assert_includes captured_command, output_path
      assert_includes result.command, "llama-benchy"
      assert_equal "stdout text", result.stdout
      assert_equal "stderr text", result.stderr
    end
  end

  test "adds --no-adapt-prompt only when prompt adaptation is disabled" do
    model = llm_models(:llama)

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      commands = {}

      [ true, false ].each do |adapt_prompt|
        capture = lambda do |*command|
          commands[adapt_prompt] = command
          File.write(output_path, "{}")
          [ "", "", Status.new(true, 0) ]
        end

        run_command(model: model, output_path: output_path, capture: capture, adapt_prompt: adapt_prompt)
      end

      refute_includes commands[true], "--no-adapt-prompt"
      assert_includes commands[false], "--no-adapt-prompt"
    end
  end

  test "redacts the api key in the recorded command" do
    model = llm_models(:gpt)
    assert model.server.api_key.present?

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      capture = lambda do |*_command|
        File.write(output_path, "{}")
        [ "", "", Status.new(true, 0) ]
      end

      result = run_command(model: model, output_path: output_path, capture: capture)

      assert_includes result.command, "--api-key [REDACTED]"
      refute_includes result.command, model.server.api_key
    end
  end

  test "raises BenchCommand::Error carrying command and streams when the process fails" do
    model = llm_models(:llama)

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      capture = ->(*_command) { [ "some stdout", "boom", Status.new(false, 1) ] }

      error = assert_raises(Inference::BenchCommand::Error) do
        run_command(model: model, output_path: output_path, capture: capture)
      end
      assert_equal "boom", error.message
      assert_includes error.command, "llama-benchy"
      assert_equal "some stdout", error.stdout
      assert_equal "boom", error.stderr
    end
  end

  test "raises BenchCommand::Error when the executable is missing" do
    model = llm_models(:llama)

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "bench.json")
      capture = ->(*_command) { raise Errno::ENOENT, "llama-benchy" }

      error = assert_raises(Inference::BenchCommand::Error) do
        run_command(model: model, output_path: output_path, capture: capture)
      end
      assert_includes error.message, "could not be executed"
      assert_includes error.command, "llama-benchy"
    end
  end
end
