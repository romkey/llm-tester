# frozen_string_literal: true

require "test_helper"

class DatabaseConfigTest < ActiveSupport::TestCase
  ENV_KEYS = %w[
    DATABASE_ADAPTER DATABASE_HOST DATABASE_PORT DATABASE_NAME
    DATABASE_USERNAME DATABASE_PASSWORD RAILS_MAX_THREADS
  ].freeze

  setup do
    @saved_env = ENV_KEYS.index_with { |key| ENV[key] }
    ENV_KEYS.each { |key| ENV.delete(key) }
  end

  teardown do
    ENV_KEYS.each do |key|
      value = @saved_env[key]
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  test "defaults to sqlite when DATABASE_ADAPTER is unset" do
    assert_equal "sqlite3", DatabaseConfig.adapter
    assert DatabaseConfig.sqlite?
    assert_not DatabaseConfig.postgresql?
  end

  test "normalizes postgres aliases to postgresql" do
    %w[postgres postgresql pg POSTGRES].each do |value|
      ENV["DATABASE_ADAPTER"] = value
      assert_equal "postgresql", DatabaseConfig.adapter, "expected #{value} to normalize"
      assert DatabaseConfig.postgresql?
    end
  end

  test "sqlite development uses a single primary database" do
    config = DatabaseConfig.environment_config("development")
    assert_equal "sqlite3", config["adapter"]
    assert_equal "storage/development.sqlite3", config["database"]
    assert_not config.key?("migrations_paths")
  end

  test "sqlite production splits into the four roles" do
    config = DatabaseConfig.environment_config("production")
    assert_equal %w[primary cache queue cable], config.keys
    assert_equal "storage/production.sqlite3", config["primary"]["database"]
    assert_equal "storage/production_cache.sqlite3", config["cache"]["database"]
    assert_equal "db/cache_migrate", config["cache"]["migrations_paths"]
    assert_not config["primary"].key?("migrations_paths")
  end

  test "postgresql connection reads details from the environment" do
    ENV["DATABASE_ADAPTER"] = "postgresql"
    ENV["DATABASE_HOST"] = "db.internal"
    ENV["DATABASE_PORT"] = "5433"
    ENV["DATABASE_NAME"] = "tester"
    ENV["DATABASE_USERNAME"] = "tester_user"
    ENV["DATABASE_PASSWORD"] = "secret"

    primary = DatabaseConfig.connection_config("production", :primary)
    assert_equal "postgresql", primary["adapter"]
    assert_equal "tester", primary["database"]
    assert_equal "db.internal", primary["host"]
    assert_equal "5433", primary["port"]
    assert_equal "tester_user", primary["username"]
    assert_equal "secret", primary["password"]

    cache = DatabaseConfig.connection_config("production", :cache)
    assert_equal "tester_cache", cache["database"]
    assert_equal "db/cache_migrate", cache["migrations_paths"]
  end

  test "postgresql database name defaults per environment" do
    ENV["DATABASE_ADAPTER"] = "postgresql"
    assert_equal "llm_tester_production", DatabaseConfig.postgresql_database("production", :primary)
    assert_equal "llm_tester_production_queue", DatabaseConfig.postgresql_database("production", :queue)
  end

  test "postgresql omits blank connection options" do
    ENV["DATABASE_ADAPTER"] = "postgresql"
    primary = DatabaseConfig.connection_config("development", :primary)
    assert_not primary.key?("host")
    assert_not primary.key?("username")
  end

  test "pool honors RAILS_MAX_THREADS" do
    ENV["RAILS_MAX_THREADS"] = "11"
    assert_equal 11, DatabaseConfig.max_threads
    assert_equal 11, DatabaseConfig.connection_config("development", :primary)["max_connections"]
  end

  test "rendered output is valid YAML for all environments" do
    parsed = YAML.safe_load(DatabaseConfig.rendered, aliases: true)
    assert_equal %w[development test production], parsed.keys
    assert_equal "sqlite3", parsed["development"]["adapter"]
    assert parsed["production"].key?("cable")
  end
end
