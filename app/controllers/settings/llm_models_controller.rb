# frozen_string_literal: true

module Settings
  class LlmModelsController < BaseController
    before_action :set_llm_model, only: %i[show edit update destroy]

    def index
      @llm_models = LlmModel.joins(:server).includes(:server).order("servers.name ASC", "llm_models.name ASC")
    end

    def show
    end

    def new
      @llm_model = LlmModel.new(enabled: true)
    end

    def create
      @llm_model = LlmModel.new(llm_model_params)

      if @llm_model.save
        redirect_to settings_llm_models_path, notice: "Model created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @llm_model.update(llm_model_params)
        redirect_to settings_llm_models_path, notice: "Model updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @llm_model.destroy!
      redirect_to settings_llm_models_path, notice: "Model deleted."
    end

    private

    def set_llm_model
      @llm_model = LlmModel.find(params[:id])
    end

    def llm_model_params
      params.expect(llm_model: %i[name server_id enabled])
    end
  end
end
