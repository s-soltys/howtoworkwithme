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

ActiveRecord::Schema[8.0].define(version: 2025_10_08_211430) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "response_id", null: false
    t.bigint "question_id", null: false
    t.text "text_value"
    t.integer "selected_option_id"
    t.integer "selected_option_ids", default: [], array: true
    t.boolean "boolean_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "numeric_value"
    t.jsonb "jsonb_value", default: {}
    t.index ["jsonb_value"], name: "index_answers_on_jsonb_value", using: :gin
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["response_id", "question_id"], name: "index_answers_on_response_id_and_question_id", unique: true
    t.index ["response_id"], name: "index_answers_on_response_id"
    t.index ["selected_option_ids"], name: "index_answers_on_selected_option_ids", using: :gin
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "questionnaire_id", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["questionnaire_id", "name"], name: "index_categories_on_questionnaire_id_and_name", unique: true
    t.index ["questionnaire_id", "position"], name: "index_categories_on_questionnaire_id_and_position"
    t.index ["questionnaire_id"], name: "index_categories_on_questionnaire_id"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_employees_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "unique_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unique_token"], name: "index_organizations_on_unique_token", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "response_id", null: false
    t.string "unique_token", null: false
    t.integer "viewed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["response_id"], name: "index_profiles_on_response_id", unique: true
    t.index ["unique_token"], name: "index_profiles_on_unique_token", unique: true
  end

  create_table "question_options", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.string "text", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id", "position"], name: "index_question_options_on_question_id_and_position"
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questionnaires", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "unique_token", null: false
    t.datetime "locked_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_questionnaires_on_organization_id"
    t.index ["unique_token"], name: "index_questionnaires_on_unique_token", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "question_type", null: false
    t.text "text", null: false
    t.integer "position", null: false
    t.boolean "required", default: true, null: false
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "position"], name: "index_questions_on_category_id_and_position"
    t.index ["category_id"], name: "index_questions_on_category_id"
  end

  create_table "responses", force: :cascade do |t|
    t.bigint "questionnaire_id", null: false
    t.bigint "employee_id"
    t.string "unique_token", null: false
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "questionnaire_id", "submitted_at"], name: "idx_on_employee_id_questionnaire_id_submitted_at_c823df6145"
    t.index ["employee_id"], name: "index_responses_on_employee_id"
    t.index ["questionnaire_id", "status"], name: "index_responses_on_questionnaire_id_and_status"
    t.index ["questionnaire_id", "submitted_at"], name: "index_responses_on_questionnaire_id_and_submitted_at"
    t.index ["questionnaire_id"], name: "index_responses_on_questionnaire_id"
    t.index ["unique_token"], name: "index_responses_on_unique_token", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "responses"
  add_foreign_key "categories", "questionnaires"
  add_foreign_key "employees", "organizations"
  add_foreign_key "profiles", "responses"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questionnaires", "organizations"
  add_foreign_key "questions", "categories"
  add_foreign_key "responses", "employees"
  add_foreign_key "responses", "questionnaires"
end
