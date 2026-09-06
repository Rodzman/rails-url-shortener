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

ActiveRecord::Schema[8.1].define(version: 2026_09_06_142714) do
  create_table "clicks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "link_id", null: false
    t.string "referrer", limit: 2048
    t.datetime "updated_at", null: false
    t.string "user_agent", limit: 512
    t.string "visitor_hash", limit: 64
    t.index ["link_id", "created_at"], name: "index_clicks_on_link_id_and_created_at"
    t.index ["link_id"], name: "index_clicks_on_link_id"
  end

  create_table "links", force: :cascade do |t|
    t.integer "clicks_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "original_url", limit: 2048, null: false
    t.string "slug", limit: 32, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_links_on_slug", unique: true
  end

  add_foreign_key "clicks", "links"
end
