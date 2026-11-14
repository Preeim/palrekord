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

ActiveRecord::Schema[7.1].define(version: 2026_11_14_180001) do
  create_table "attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "record_id", null: false
    t.string "file_type", limit: 20, null: false
    t.string "file_path_or_url", limit: 500
    t.string "original_filename", limit: 255
    t.text "text_content"
    t.datetime "uploaded_at", default: -> { "CURRENT_TIMESTAMP(6)" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_id"], name: "index_attachments_on_record_id"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 150, null: false
    t.text "description"
    t.string "unit", limit: 30, null: false
    t.string "value_type", limit: 20, default: "DOUBLE", null: false
    t.string "sort_direction", limit: 10, default: "DESC", null: false
    t.boolean "is_archived", default: false, null: false
    t.string "recommended_file_type", limit: 20
    t.string "verification_hint", limit: 255
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_categories_on_created_by_id"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "invite_codes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 64, null: false
    t.string "label", limit: 100
    t.integer "max_uses"
    t.integer "uses_count", default: 0, null: false
    t.datetime "expires_at"
    t.boolean "is_active", default: true, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_invite_codes_on_code", unique: true
    t.index ["created_by_id"], name: "index_invite_codes_on_created_by_id"
  end

  create_table "records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "value", limit: 100, null: false
    t.decimal "sort_value", precision: 16, scale: 4, null: false
    t.date "achieved_at", null: false
    t.text "note"
    t.string "status", limit: 20, default: "PENDING", null: false
    t.text "admin_comment"
    t.bigint "reviewed_by_id"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "status", "sort_value", "achieved_at"], name: "idx_records_leaderboard"
    t.index ["category_id"], name: "index_records_on_category_id"
    t.index ["reviewed_by_id"], name: "index_records_on_reviewed_by_id"
    t.index ["user_id"], name: "index_records_on_user_id"
  end

  create_table "seasons", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 120, null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_seasons_on_created_by_id"
    t.index ["ends_at"], name: "index_seasons_on_ends_at"
    t.index ["name"], name: "index_seasons_on_name", unique: true
    t.index ["starts_at", "ends_at"], name: "index_seasons_on_starts_at_and_ends_at"
    t.index ["starts_at"], name: "index_seasons_on_starts_at"
  end

  create_table "settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", limit: 100, null: false
    t.string "value", limit: 255, null: false
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "username", limit: 50, null: false
    t.string "display_name", limit: 100, null: false
    t.string "email", limit: 255
    t.string "password_digest", limit: 255, null: false
    t.string "role", limit: 20, default: "TAG", null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "must_change_password", default: false, null: false
    t.datetime "confirmed_at"
    t.datetime "last_login_at"
    t.bigint "invite_code_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invite_code_id"], name: "index_users_on_invite_code_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "attachments", "records", on_delete: :cascade
  add_foreign_key "categories", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "invite_codes", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "records", "categories", on_delete: :cascade
  add_foreign_key "records", "users", column: "reviewed_by_id", on_delete: :nullify
  add_foreign_key "records", "users", on_delete: :cascade
  add_foreign_key "seasons", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "users", "invite_codes", on_delete: :nullify
end
