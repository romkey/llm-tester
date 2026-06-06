# frozen_string_literal: true

require "open3"

module Inference
  class BenchCommand
    Result = Data.define(:command, :stdout, :stderr)

    class Error < StandardError
      attr_reader :command, :stdout, :stderr

      def initialize(message = nil, command: nil, stdout: nil, stderr: nil)
        super(message)
        @command = command
        @stdout = stdout
        @stderr = stderr
      end
    end

    def self.run(model:, output_path:, pp:, tg:, depth:, runs:, latency_mode:, capture: Open3.method(:capture3))
      new.run(
        model: model,
        output_path: output_path,
        pp: pp,
        tg: tg,
        depth: depth,
        runs: runs,
        latency_mode: latency_mode,
        capture: capture
      )
    end

    def run(model:, output_path:, pp:, tg:, depth:, runs:, latency_mode:, capture: Open3.method(:capture3))
      command = build_command(
        model: model,
        output_path: output_path,
        pp: pp,
        tg: tg,
        depth: depth,
        runs: runs,
        latency_mode: latency_mode
      )
      printable = redact(command).join(" ")

      begin
        stdout, stderr, status = capture.call(*command)
      rescue Errno::ENOENT => e
        raise Error.new("llama-benchy could not be executed: #{e.message}", command: printable)
      end

      unless status.success? && File.file?(output_path)
        message = stderr.presence || "llama-benchy failed with exit status #{status.exitstatus}"
        raise Error.new(message, command: printable, stdout: stdout, stderr: stderr)
      end

      Result.new(command: printable, stdout: stdout, stderr: stderr)
    end

    private

    def build_command(model:, output_path:, pp:, tg:, depth:, runs:, latency_mode:)
      command = [
        "llama-benchy",
        "--base-url", model.server.openai_compatible_base_url,
        "--model", model.name,
        "--format", "json",
        "--save-result", output_path,
        "--pp", pp.to_s,
        "--tg", tg.to_s,
        "--depth", depth.to_s,
        "--runs", runs.to_s,
        "--latency-mode", latency_mode,
        "--skip-coherence",
        "--no-warmup"
      ]
      command += [ "--api-key", model.server.api_key ] if model.server.api_key.present?
      command
    end

    def redact(command)
      redacted = command.dup
      key_index = redacted.index("--api-key")
      redacted[key_index + 1] = "[REDACTED]" if key_index && redacted[key_index + 1]
      redacted
    end
  end
end
