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

ActiveRecord::Schema.define(version: 2020_07_23_123556) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "contributors", force: :cascade do |t|
    t.string "github_username"
    t.integer "github_id"
    t.boolean "core", default: false
    t.boolean "bot", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "dependencies", force: :cascade do |t|
    t.integer "version_id"
    t.integer "package_id"
    t.string "package_name"
    t.string "platform"
    t.string "kind"
    t.boolean "optional", default: false
    t.string "requirements"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["package_id"], name: "index_dependencies_on_package_id"
    t.index ["version_id"], name: "index_dependencies_on_version_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "github_id"
    t.string "actor"
    t.string "event_type"
    t.string "action"
    t.integer "repository_id"
    t.string "repository_full_name"
    t.string "org"
    t.jsonb "payload", default: "{}", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["actor"], name: "index_events_on_actor"
    t.index ["github_id"], name: "index_events_on_github_id"
    t.index ["org", "event_type"], name: "index_events_on_org_and_event_type"
  end

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
    t.string "milestone_name"
    t.integer "milestone_id"
    t.string "labels", default: [], array: true
    t.boolean "locked"
    t.datetime "merged_at"
    t.boolean "draft"
    t.datetime "first_response_at"
    t.integer "response_time"
    t.bigint "github_id"
    t.datetime "last_synced_at"
    t.index ["collabs"], name: "index_issues_on_collabs", using: :gin
    t.index ["created_at"], name: "index_issues_on_created_at"
    t.index ["org"], name: "index_issues_on_org"
    t.index ["repo_full_name"], name: "index_issues_on_repo_full_name"
    t.index ["state"], name: "index_issues_on_state"
    t.index ["user"], name: "index_issues_on_user"
  end

  create_table "manifests", force: :cascade do |t|
    t.integer "repository_id"
    t.string "platform"
    t.string "filepath"
    t.string "sha"
    t.string "branch"
    t.string "kind"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["repository_id"], name: "index_manifests_on_repository_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.integer "github_id"
    t.boolean "internal", default: false
    t.boolean "collaborator", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "docker_hub_org"
    t.integer "search_results_count", default: 0
    t.integer "events_count", default: 0
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.string "platform"
    t.text "description"
    t.text "keywords"
    t.string "homepage"
    t.string "licenses"
    t.string "repository_url"
    t.integer "repository_id"
    t.string "normalized_licenses", default: [], array: true
    t.integer "versions_count", default: 0, null: false
    t.datetime "latest_release_published_at"
    t.string "latest_release_number"
    t.string "keywords_array", default: [], array: true
    t.integer "dependents_count", default: 0, null: false
    t.string "language"
    t.string "status"
    t.datetime "last_synced_at"
    t.integer "dependent_repos_count"
    t.integer "runtime_dependencies_count"
    t.string "latest_stable_release_number"
    t.string "latest_stable_release_published_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "license_normalized", default: false
    t.integer "collab_dependent_repos_count"
    t.integer "outdated"
    t.index ["platform", "name"], name: "index_packages_on_platform_and_name", unique: true
  end

  create_table "repositories", force: :cascade do |t|
    t.integer "github_id"
    t.string "full_name"
    t.string "org"
    t.string "language"
    t.boolean "archived"
    t.boolean "fork"
    t.string "description"
    t.datetime "pushed_at"
    t.integer "size"
    t.integer "stargazers_count"
    t.integer "open_issues_count"
    t.integer "forks_count"
    t.integer "subscribers_count"
    t.string "default_branch"
    t.datetime "last_sync_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "etag"
  end

  create_table "repository_dependencies", force: :cascade do |t|
    t.integer "package_id"
    t.integer "manifest_id"
    t.integer "repository_id"
    t.boolean "optional", default: false
    t.string "package_name"
    t.string "platform"
    t.string "requirements"
    t.string "kind"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "direct", default: false
    t.index ["manifest_id"], name: "index_repository_dependencies_on_manifest_id"
    t.index ["package_id"], name: "index_repository_dependencies_on_package_id"
    t.index ["repository_id"], name: "index_repository_dependencies_on_repository_id"
  end

  create_table "search_queries", force: :cascade do |t|
    t.string "query"
    t.string "kind"
    t.string "sort"
    t.string "order"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "search_results", force: :cascade do |t|
    t.integer "search_query_id"
    t.string "kind"
    t.string "repository_full_name"
    t.string "org"
    t.string "title"
    t.string "html_url"
    t.jsonb "text_matches", default: "{}", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tags", force: :cascade do |t|
    t.integer "repository_id"
    t.string "name"
    t.string "sha"
    t.string "kind"
    t.datetime "published_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "versions", force: :cascade do |t|
    t.integer "package_id"
    t.string "number"
    t.datetime "published_at"
    t.integer "runtime_dependencies_count"
    t.string "spdx_expression"
    t.jsonb "original_license"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["package_id", "number"], name: "index_versions_on_package_id_and_number", unique: true
  end

end
