# frozen_string_literal: true

class LlmModelsController < ApplicationController
  def show
    @llm_model = LlmModel.includes(:server).find(params[:id])
    @health_checks = @llm_model.health_check_results
  end
end
