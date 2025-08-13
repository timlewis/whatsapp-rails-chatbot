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

ActiveRecord::Schema[8.0].define(version: 2025_08_13_140911) do
  create_table "acidic_job_entries", force: :cascade do |t|
    t.integer "execution_id", null: false
    t.string "step", null: false
    t.string "action", null: false
    t.datetime "timestamp", null: false
    t.json "data", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_id", "step", "action"], name: "index_acidic_job_entries_on_execution_id_and_step_and_action"
    t.index ["execution_id"], name: "index_acidic_job_entries_on_execution_id"
  end

  create_table "acidic_job_executions", force: :cascade do |t|
    t.string "idempotency_key", null: false
    t.json "serialized_job", default: "{}", null: false
    t.datetime "last_run_at"
    t.datetime "locked_at"
    t.string "recover_to"
    t.json "definition", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_acidic_job_executions_on_idempotency_key", unique: true
  end

  create_table "acidic_job_values", force: :cascade do |t|
    t.integer "execution_id", null: false
    t.string "key", null: false
    t.json "value", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_id", "key"], name: "index_acidic_job_values_on_execution_id_and_key", unique: true
    t.index ["execution_id"], name: "index_acidic_job_values_on_execution_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email_address"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_admin_users_on_email_address", unique: true
  end

  create_table "chats", force: :cascade do |t|
    t.string "model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.string "role"
    t.text "content"
    t.string "model_id"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.integer "tool_call_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "personas", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.text "base_prompt", null: false
    t.boolean "config_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["config_default"], name: "index_personas_on_config_default", unique: true, where: "config_default = true"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_sessions_on_admin_user_id"
  end

  create_table "tool_calls", force: :cascade do |t|
    t.integer "message_id", null: false
    t.string "tool_call_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "arguments", default: {}, null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "whatsapp_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["whatsapp_number"], name: "index_users_on_whatsapp_number", unique: true
  end

  add_foreign_key "acidic_job_entries", "acidic_job_executions", column: "execution_id"
  add_foreign_key "acidic_job_values", "acidic_job_executions", column: "execution_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chats", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "sessions", "admin_users"
  add_foreign_key "tool_calls", "messages"
end
