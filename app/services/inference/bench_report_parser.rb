# frozen_string_literal: true

module Inference
  class BenchReportParser
    class << self
      def summary(report)
        benchmark = primary_benchmark(report)
        return {} unless benchmark

        {
          prompt_tokens: benchmark["prompt_size"],
          generation_tokens: benchmark["response_size"],
          context_depth: benchmark["context_size"] || 0,
          prompt_tokens_per_second: mean_metric(benchmark, "pp_throughput"),
          generation_tokens_per_second: mean_metric(benchmark, "tg_throughput"),
          peak_generation_tokens_per_second: mean_metric(benchmark, "peak_throughput"),
          time_to_first_token_ms: mean_metric(benchmark, "e2e_ttft"),
          estimated_prompt_processing_ms: mean_metric(benchmark, "est_ppt")
        }
      end

      # llama-benchy exits successfully and still writes a result file when the
      # model server errors mid-run; the benchmark entry just has null
      # throughput metrics. Treat a run as usable only when it actually produced
      # prompt- and token-generation throughput numbers.
      def usable?(report)
        benchmark = primary_benchmark(report)
        return false unless benchmark

        mean_metric(benchmark, "pp_throughput") && mean_metric(benchmark, "tg_throughput")
      end

      def primary_benchmark(report)
        report.fetch("benchmarks", []).find do |entry|
          entry["context_size"].to_i.zero? && !entry["is_context_prefill_phase"]
        end
      end

      def mean_metric(benchmark, key)
        benchmark.dig(key, "mean")&.to_f
      end
    end
  end
end
