# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_02_14_102051) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "issues", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.string "state"
    t.integer "number"
    t.string "html_url"
    t.integer "comments_count"
    t.string "user"
    t.string "repo_full_name"
    t.datetime "closed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "org"
    t.string "collabs", default: [], array: true
    t.index ["org"], name: "index_issues_on_org"
    t.index ["repo_full_name"], name: "index_issues_on_repo_full_name"
    t.index ["state"], name: "index_issues_on_state"
    t.index ["user"], name: "index_issues_on_user"
  end

end
