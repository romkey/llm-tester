# frozen_string_literal: true

class SyncServerModelsJob < ApplicationJob
  queue_as :default

  def perform(server_id)
    server = Server.find(server_id)
    Inference::ModelSync.sync(server)
  end
end
