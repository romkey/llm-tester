# frozen_string_literal: true

# Copies application data from a SQLite database file into the database the
# application is currently connected to (typically PostgreSQL).
#
# It walks every table that exists in both the source and the target, casts
# each value through the target's column types (so SQLite's 0/1 booleans and
# string timestamps land correctly in PostgreSQL), and inserts the rows while
# referential integrity is disabled. Primary-key sequences are reset afterwards
# on PostgreSQL so future inserts don't collide with the migrated ids.
#
# Usage:
#   DATABASE_ADAPTER=postgresql bin/rails db:migrate_from_sqlite
class SqliteToPostgresMigrator
  # Dedicated connection holder for the SQLite source. Using a named class keeps
  # its connection isolated from ActiveRecord::Base; an anonymous class would
  # resolve back to the primary connection and clobber the live database.
  class SourceConnection < ActiveRecord::Base
    self.abstract_class = true
  end

  # Rails bookkeeping tables are managed by schema load / migrate on the target,
  # so we never copy them.
  EXCLUDED_TABLES = %w[schema_migrations ar_internal_metadata].freeze
  BATCH_SIZE = 500

  attr_reader :results

  def initialize(sqlite_path:, target_class: ActiveRecord::Base, logger: nil)
    @sqlite_path = sqlite_path.to_s
    @target_class = target_class
    @logger = logger
    @results = {}
  end

  # Returns a Hash of table_name => rows_copied.
  def migrate!
    unless File.exist?(@sqlite_path)
      raise ArgumentError, "SQLite database not found: #{@sqlite_path}"
    end

    target_connection.disable_referential_integrity do
      tables.each { |table| @results[table] = copy_table(table) }
    end

    reset_sequences if postgresql_target?
    @results
  ensure
    SourceConnection.remove_connection if @source_established
  end

  private

  def log(message)
    @logger&.info(message)
  end

  def source_connection
    unless @source_established
      SourceConnection.establish_connection(adapter: "sqlite3", database: @sqlite_path)
      @source_established = true
    end

    SourceConnection.connection
  end

  def target_connection
    @target_class.connection
  end

  def postgresql_target?
    target_connection.adapter_name.downcase.include?("postgres")
  end

  def tables
    shared = source_connection.tables & target_connection.tables
    shared - EXCLUDED_TABLES
  end

  def copy_table(table)
    model = model_for(table)
    target_columns = model.column_names
    types = model.attribute_types

    quoted = source_connection.quote_table_name(table)
    rows = source_connection.select_all("SELECT * FROM #{quoted}").to_a
    return 0 if rows.empty?

    rows.each_slice(BATCH_SIZE) do |batch|
      casted = batch.map { |row| cast_row(row, target_columns, types) }
      model.insert_all(casted)
    end

    log("Copied #{rows.size} rows into #{table}")
    rows.size
  end

  def cast_row(row, target_columns, types)
    target_columns.each_with_object({}) do |column, attributes|
      next unless row.key?(column)

      type = types[column]
      value = row[column]
      attributes[column] = type ? type.cast(value) : value
    end
  end

  def model_for(table)
    Class.new(@target_class) do
      self.table_name = table
      self.inheritance_column = :_type_disabled
    end
  end

  def reset_sequences
    @results.each_key do |table|
      target_connection.reset_pk_sequence!(table)
    rescue StandardError => e
      log("Skipped sequence reset for #{table}: #{e.message}")
    end
  end
end
