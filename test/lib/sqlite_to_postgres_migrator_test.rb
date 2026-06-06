# frozen_string_literal: true

require "test_helper"
require "tempfile"

# Exercises the copy logic by migrating between two throwaway SQLite databases.
# disable_referential_integrity is a no-op on SQLite and sequence resets only
# run on PostgreSQL, so the row-copying and type-casting paths are covered here
# without needing a live PostgreSQL server.
# Named connection holders so establishing a connection cannot fall back to
# (and clobber) ActiveRecord::Base's primary connection.
class MigratorTestTarget < ActiveRecord::Base
  self.abstract_class = true
end

class MigratorTestSource < ActiveRecord::Base
  self.abstract_class = true
end

class SqliteToPostgresMigratorTest < ActiveSupport::TestCase
  # This test operates only on throwaway SQLite files via dedicated connection
  # classes. Transactional fixtures would roll back the writes we make to the
  # source database before the migrator (on a separate connection) can read
  # them, so commit normally instead.
  self.use_transactional_tests = false

  setup do
    @source_file = Tempfile.new([ "migrator_source", ".sqlite3" ])
    @target_file = Tempfile.new([ "migrator_target", ".sqlite3" ])
    [ @source_file, @target_file ].each(&:close)

    MigratorTestTarget.establish_connection(adapter: "sqlite3", database: @target_file.path)
    @target_class = MigratorTestTarget
    build_schema(@target_class.connection)

    MigratorTestSource.establish_connection(adapter: "sqlite3", database: @source_file.path)
    build_schema(MigratorTestSource.connection)
    seed(MigratorTestSource.connection)
    MigratorTestSource.remove_connection
  end

  teardown do
    MigratorTestTarget.remove_connection
    [ @source_file, @target_file ].each(&:unlink)
  end

  test "copies rows from every shared table" do
    results = migrate!

    assert_equal 2, results["widgets"]
    assert_equal 1, results["gizmos"]
    assert_equal 2, target_count("widgets")
    assert_equal 1, target_count("gizmos")
  end

  test "preserves UTC timestamps even when the app time zone is not UTC" do
    # SQLite stores naive UTC strings; a non-UTC Time.zone must not shift them.
    Time.use_zone("America/Los_Angeles") do
      migrate!
    end

    created_at = @target_class.connection.select_value("SELECT created_at FROM widgets WHERE id = 1")
    assert_includes created_at.to_s, "2026-01-02 03:04:05"
  end

  test "inserts referenced tables before their dependents so foreign keys hold" do
    # gizmos.widget_id references widgets; with foreign keys enforced the copy
    # only succeeds if widgets are inserted first. (gizmos sorts before widgets
    # alphabetically, so this fails without dependency ordering.)
    @target_class.connection.execute("PRAGMA foreign_keys = ON")

    migrate!

    gizmo = @target_class.connection.select_one("SELECT widget_id FROM gizmos")
    assert_equal 1, gizmo["widget_id"]
  end

  test "casts sqlite integers and strings to the target column types" do
    migrate!

    rows = @target_class.connection.select_all("SELECT * FROM widgets ORDER BY id").to_a
    enabled_values = rows.map { |row| row["enabled"] }

    # SQLite stores booleans as 0/1; after casting they round-trip as booleans.
    assert_equal [ true, false ], enabled_values.map { |v| ActiveModel::Type::Boolean.new.cast(v) }
    assert rows.first["created_at"].present?
  end

  test "never copies Rails bookkeeping tables" do
    results = migrate!

    assert_not results.key?("schema_migrations")
    assert_equal 0, target_count("schema_migrations")
  end

  test "raises when the source database is missing" do
    migrator = SqliteToPostgresMigrator.new(sqlite_path: "/tmp/does-not-exist-#{SecureRandom.hex}.sqlite3", target_class: @target_class)

    assert_raises(ArgumentError) { migrator.migrate! }
  end

  private

  def migrate!
    SqliteToPostgresMigrator.new(sqlite_path: @source_file.path, target_class: @target_class).migrate!
  end

  def build_schema(connection)
    connection.create_table(:widgets, force: true) do |t|
      t.string :name
      t.boolean :enabled
      t.datetime :created_at
    end

    connection.create_table(:gizmos, force: true) do |t|
      t.string :label
      t.references :widget, foreign_key: true
    end

    connection.execute("CREATE TABLE IF NOT EXISTS schema_migrations (version varchar PRIMARY KEY)")
  end

  def seed(connection)
    connection.execute("INSERT INTO widgets (id, name, enabled, created_at) VALUES (1, 'first', 1, '2026-01-02 03:04:05')")
    connection.execute("INSERT INTO widgets (id, name, enabled, created_at) VALUES (2, 'second', 0, '2026-01-02 03:04:06')")
    connection.execute("INSERT INTO gizmos (id, label, widget_id) VALUES (1, 'gizmo', 1)")
    connection.execute("INSERT INTO schema_migrations (version) VALUES ('20260101000000')")
  end

  def target_count(table)
    @target_class.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i
  end
end
