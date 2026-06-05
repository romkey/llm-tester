# frozen_string_literal: true

require "open3"

module Inference
  class BenchCommand
    class Error < StandardError; end

    def self.run(model, output_path:, pp:, tg:, depth:, runs:, latency_mode:)
      new.run(
        model: model,
        output_path: output_path,
        pp: pp,
        tg: tg,
        depth: depth,
        runs: runs,
        latency_mode: latency_mode
      )
    end

    def run(model:, output_path:, pp:, tg:, depth:, runs:, latency_mode:)
      command = build_command(
        model: model,
        output_path: output_path,
        pp: pp,
        tg: tg,
        depth: depth,
        runs: runs,
        latency_mode: latency_mode
      )

      _stdout, stderr, status = Open3.capture3(*command)
      return if status.success? && File.file?(output_path)

      message = stderr.presence || "llama-benchy failed with exit status #{status.exitstatus}"
      raise Error, message
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
  end
end
