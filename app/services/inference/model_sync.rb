# frozen_string_literal: true

module Inference
  class ModelSync
    def self.sync(server)
      new(server).sync
    end

    def initialize(server)
      @server = server
    end

    def sync
      client = Client.for(server)
      remote_names = client.list_models
      created = []

      remote_names.each do |name|
        model = server.llm_models.find_or_create_by!(name: name)
        created << model if model.previously_new_record?
      end

      created
    rescue Error
      raise
    end

    private

    attr_reader :server
  end
end
