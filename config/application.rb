require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/app_time_zone"

module LlmTester
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks app_time_zone.rb])
    config.autoload_paths << Rails.root.join("app/services")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Use the TZ environment variable for the display time zone when it is a
    # recognized zone; otherwise fall back to the Rails default (UTC).
    if (zone_name = AppTimeZone.resolve(ENV["TZ"]))
      config.time_zone = zone_name
    end

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
