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

ActiveRecord::Schema[8.1].define(version: 2026_07_09_101416) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.bigint "response_session_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value_json", default: {}, null: false
    t.decimal "value_number"
    t.text "value_text"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["response_session_id"], name: "index_answers_on_response_session_id"
  end

  create_table "question_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.integer "position"
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.text "prompt", null: false
    t.string "question_type", null: false
    t.boolean "required", default: false, null: false
    t.jsonb "settings", default: {}, null: false
    t.bigint "survey_id", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_id"], name: "index_questions_on_survey_id"
  end

  create_table "response_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "respondent_identifier"
    t.datetime "submitted_at"
    t.bigint "survey_id", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_id"], name: "index_response_sessions_on_survey_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "public_token", null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["public_token"], name: "index_surveys_on_public_token", unique: true
    t.index ["user_id"], name: "index_surveys_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "response_sessions"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "surveys"
  add_foreign_key "response_sessions", "surveys"
  add_foreign_key "sessions", "users"
  add_foreign_key "surveys", "users"
end
