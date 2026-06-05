# frozen_string_literal: true

module Settings
  class ServersController < BaseController
    before_action :set_server, only: %i[show edit update destroy sync_models]

    def index
      @servers = Server.order(:name)
    end

    def show
    end

    def new
      @server = Server.new
    end

    def create
      @server = Server.new(server_params)

      if @server.save
        sync_models_after_save(@server)
        redirect_to settings_servers_path, notice: "Server created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @server.update(server_params)
        sync_models_after_save(@server)
        redirect_to settings_servers_path, notice: "Server updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @server.destroy!
      redirect_to settings_servers_path, notice: "Server deleted."
    end

    def sync_models
      Inference::ModelSync.sync(@server)
      redirect_to settings_servers_path, notice: "Models synced for #{@server.name}."
    rescue Inference::Error => e
      redirect_to settings_servers_path, alert: "Could not sync models: #{e.message}"
    end

    private

    def set_server
      @server = Server.find(params[:id])
    end

    def server_params
      params.expect(server: %i[name hostname api_type api_key])
    end

    def sync_models_after_save(server)
      Inference::ModelSync.sync(server)
    rescue Inference::Error
      nil
    end
  end
end
