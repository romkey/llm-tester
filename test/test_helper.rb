ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{worker}"
    end

    fixtures :all
  end
end
