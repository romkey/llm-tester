# frozen_string_literal: true

require "yaml"

# Builds the Active Record connection configuration from the environment so the
# application can run on either SQLite (the default) or PostgreSQL without
# editing config/database.yml.
#
# Set DATABASE_ADAPTER=postgresql to switch. PostgreSQL connection details are
# read from these variables (all optional; sensible defaults are used):
#
#   DATABASE_HOST       e.g. localhost or a container/service name
#   DATABASE_PORT       defaults to 5432
#   DATABASE_NAME       base name; defaults to llm_tester_<env>
#   DATABASE_USERNAME
#   DATABASE_PASSWORD
#
# Every environment uses a single database. solid_cache and solid_cable keep
# their tables alongside the application schema (see config/cache.yml and
# config/cable.yml), so there is no separate cache/queue/cable database.
module DatabaseConfig
  SQLITE_ADAPTER = "sqlite3"
  POSTGRESQL_ADAPTER = "postgresql"
  POSTGRESQL_ALIASES = %w[postgresql postgres pg].freeze

  module_function

  def adapter
    name = ENV["DATABASE_ADAPTER"].to_s.strip.downcase
    return SQLITE_ADAPTER if name.empty?

    POSTGRESQL_ALIASES.include?(name) ? POSTGRESQL_ADAPTER : name
  end

  def postgresql?
    adapter == POSTGRESQL_ADAPTER
  end

  def sqlite?
    adapter == SQLITE_ADAPTER
  end

  def max_threads
    Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
  end

  # Returns the full parsed configuration as a Hash keyed by environment.
  def configuration
    {
      "development" => environment_config("development"),
      "test" => environment_config("test"),
      "production" => environment_config("production")
    }
  end

  # The YAML document consumed by config/database.yml.
  def rendered
    configuration.to_yaml
  end

  def environment_config(env)
    postgresql? ? postgresql_connection(env) : sqlite_connection(env)
  end

  def sqlite_connection(env)
    {
      "adapter" => SQLITE_ADAPTER,
      "max_connections" => max_threads,
      "timeout" => 5000,
      "database" => "storage/#{env}.sqlite3"
    }
  end

  def postgresql_connection(env)
    {
      "adapter" => POSTGRESQL_ADAPTER,
      "encoding" => "unicode",
      "pool" => max_threads,
      "database" => postgresql_database(env),
      "host" => ENV["DATABASE_HOST"].presence,
      "port" => ENV["DATABASE_PORT"].presence,
      "username" => ENV["DATABASE_USERNAME"].presence,
      "password" => ENV["DATABASE_PASSWORD"].presence
    }.compact
  end

  def postgresql_database(env)
    ENV["DATABASE_NAME"].presence || "llm_tester_#{env}"
  end
end
