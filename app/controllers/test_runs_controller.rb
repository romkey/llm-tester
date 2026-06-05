# frozen_string_literal: true

class TestRunsController < ApplicationController
  def index
    @pagy, @test_runs = pagy(
      TestRun.includes(:test_definition, :llm_model, :server).recent_first
    )
  end

  def show
    @test_run = TestRun.includes(:test_definition, :llm_model, :server).find(params[:id])
  end
end
