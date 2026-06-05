# frozen_string_literal: true

class ServersController < ApplicationController
  def index
    @servers = Server.includes(llm_models: { test_definitions: :test_runs }).order(:name)
  end

  def sync_models
    server = Server.find(params[:id])
    Inference::ModelSync.sync(server)
    redirect_to root_path, notice: "Models synced for #{server.name}."
  rescue Inference::Error => e
    redirect_to root_path, alert: "Could not sync models: #{e.message}"
  end
end
