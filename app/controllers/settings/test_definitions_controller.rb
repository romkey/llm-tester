# frozen_string_literal: true

module Settings
  class TestDefinitionsController < BaseController
    before_action :set_test_definition, only: %i[edit update destroy run_now]

    def index
      @test_definitions = TestDefinition.includes(llm_model: :server).order(:name)
    end

    def new
      @test_definition = TestDefinition.new(frequency_minutes: 60, enabled: true)
    end

    def create
      @test_definition = TestDefinition.new(test_definition_params)

      if @test_definition.save
        redirect_to settings_test_definitions_path, notice: "Test created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @test_definition.update(test_definition_params)
        redirect_to settings_test_definitions_path, notice: "Test updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @test_definition.destroy!
      redirect_to settings_test_definitions_path, notice: "Test deleted."
    end

    def run_now
      RunTestJob.perform_later(@test_definition.id)
      redirect_to settings_test_definitions_path, notice: "Test queued to run."
    end

    private

    def set_test_definition
      @test_definition = TestDefinition.find(params[:id])
    end

    def test_definition_params
      params.expect(test_definition: %i[
        name prompt response_type expected_response regex_pattern
        frequency_minutes llm_model_id enabled run_on_all_models
      ])
    end
  end
end
