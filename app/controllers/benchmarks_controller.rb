# frozen_string_literal: true

class BenchmarksController < ApplicationController
  def index
    @latest_runs = BenchmarkRun.latest_per_model
    @recent_runs = BenchmarkRun.recent_first.includes(llm_model: :server).limit(50)
  end
end
