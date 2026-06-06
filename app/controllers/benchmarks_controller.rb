# frozen_string_literal: true

class BenchmarksController < ApplicationController
  def index
    @latest_runs = BenchmarkRun.latest_per_model
    @recent_runs = BenchmarkRun.recent_first.includes(llm_model: :server).limit(50)
  end

  def show
    @benchmark_run = BenchmarkRun.includes(llm_model: :server).find(params[:id])
  end

  def run_now
    count = LlmModel.enabled.count

    if count.zero?
      redirect_to benchmarks_path, alert: "No enabled models to benchmark."
    else
      RunScheduledBenchmarksJob.perform_later
      redirect_to benchmarks_path, notice: "Benchmarks queued for #{helpers.pluralize(count, "enabled model")}."
    end
  end
end
