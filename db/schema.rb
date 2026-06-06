# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_06_050000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "benchmark_runs", force: :cascade do |t|
    t.text "command"
    t.integer "context_depth"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.float "estimated_prompt_processing_ms"
    t.datetime "finished_at"
    t.integer "generation_tokens"
    t.float "generation_tokens_per_second"
    t.integer "llm_model_id", null: false
    t.text "output"
    t.float "peak_generation_tokens_per_second"
    t.integer "prompt_tokens"
    t.float "prompt_tokens_per_second"
    t.text "raw_report"
    t.integer "server_id", null: false
    t.datetime "started_at"
    t.string "status", null: false
    t.float "time_to_first_token_ms"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_benchmark_runs_on_created_at"
    t.index ["llm_model_id"], name: "index_benchmark_runs_on_llm_model_id"
    t.index ["server_id"], name: "index_benchmark_runs_on_server_id"
  end

  create_table "llm_models", force: :cascade do |t|
    t.boolean "benchmark_adapt_prompt", default: true, null: false
    t.string "benchmark_latency_mode", default: "generation", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "name", null: false
    t.integer "server_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id", "name"], name: "index_llm_models_on_server_id_and_name", unique: true
    t.index ["server_id"], name: "index_llm_models_on_server_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "api_key"
    t.string "api_type", null: false
    t.datetime "created_at", null: false
    t.string "hostname", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_servers_on_name", unique: true
  end

  create_table "test_definitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.text "expected_response"
    t.integer "frequency_minutes", default: 60, null: false
    t.datetime "last_run_at"
    t.integer "llm_model_id"
    t.string "name", null: false
    t.text "prompt", null: false
    t.string "regex_pattern"
    t.string "response_type", default: "exact", null: false
    t.boolean "run_on_all_models", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["llm_model_id"], name: "index_test_definitions_on_llm_model_id"
  end

  create_table "test_runs", force: :cascade do |t|
    t.text "actual_response"
    t.integer "completion_tokens"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.float "latency_ms"
    t.integer "llm_model_id", null: false
    t.integer "prompt_tokens"
    t.integer "server_id", null: false
    t.datetime "started_at"
    t.string "status", null: false
    t.integer "test_definition_id", null: false
    t.float "tokens_per_second"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_test_runs_on_created_at"
    t.index ["llm_model_id"], name: "index_test_runs_on_llm_model_id"
    t.index ["server_id"], name: "index_test_runs_on_server_id"
    t.index ["status"], name: "index_test_runs_on_status"
    t.index ["test_definition_id"], name: "index_test_runs_on_test_definition_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "benchmark_runs", "llm_models"
  add_foreign_key "benchmark_runs", "servers"
  add_foreign_key "llm_models", "servers"
  add_foreign_key "test_definitions", "llm_models"
  add_foreign_key "test_runs", "llm_models"
  add_foreign_key "test_runs", "servers"
  add_foreign_key "test_runs", "test_definitions"
end
