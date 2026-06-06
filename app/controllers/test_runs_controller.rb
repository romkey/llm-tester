# frozen_string_literal: true

class TestRunsController < ApplicationController
  def index
    scope = TestRun.includes(:test_definition, :llm_model, :server).recent_first
    scope = scope.where(test_definition_id: params[:test_definition_id]) if params[:test_definition_id].present?
    scope = scope.where(llm_model_id: params[:llm_model_id]) if params[:llm_model_id].present?
    scope = scope.where(status: params[:status]) if TestRun::STATUSES.include?(params[:status])

    @pagy, @test_runs = pagy(scope)
    @test_definitions = TestDefinition.order(:name)
    @llm_models = LlmModel.includes(:server).order(:name)
  end

  def show
    @test_run = TestRun.includes(:test_definition, :llm_model, :server).find(params[:id])
  end
end
