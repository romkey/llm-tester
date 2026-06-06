# frozen_string_literal: true

namespace :db do
  desc "Copy data from a SQLite database into the current (PostgreSQL) database. " \
       "Override the source file with SQLITE_DATABASE=path/to.sqlite3."
  task migrate_from_sqlite: :environment do
    require Rails.root.join("lib/database_config").to_s

    unless DatabaseConfig.postgresql?
      abort <<~MSG
        The current database adapter is '#{DatabaseConfig.adapter}', not PostgreSQL.
        Set DATABASE_ADAPTER=postgresql (and the DATABASE_* vars) and create/migrate
        the target schema before running this task, e.g.:

          DATABASE_ADAPTER=postgresql bin/rails db:create db:schema:load
          DATABASE_ADAPTER=postgresql bin/rails db:migrate_from_sqlite
      MSG
    end

    sqlite_path = ENV["SQLITE_DATABASE"].presence ||
                  Rails.root.join("storage", "#{Rails.env}.sqlite3").to_s

    puts "Migrating data from #{sqlite_path} into #{ActiveRecord::Base.connection.current_database}..."

    migrator = SqliteToPostgresMigrator.new(sqlite_path: sqlite_path, logger: Rails.logger)
    results = migrator.migrate!

    if results.empty?
      puts "No tables were copied (nothing to migrate)."
    else
      results.sort.each { |table, count| puts format("  %-32s %d rows", table, count) }
      puts "Done. Copied #{results.values.sum} rows across #{results.size} tables."
    end
  end
end
