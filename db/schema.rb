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

ActiveRecord::Schema[8.1].define(version: 2026_04_14_001921) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "city", null: false
    t.string "complement"
    t.datetime "created_at", null: false
    t.string "document", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "number", null: false
    t.integer "person_type", default: 0, null: false
    t.string "phone"
    t.string "state", null: false
    t.integer "status", default: 0, null: false
    t.string "street", null: false
    t.datetime "updated_at", null: false
    t.string "zip_code", null: false
    t.index ["document"], name: "index_customers_on_document", unique: true
    t.index ["status"], name: "index_customers_on_status"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "license_plate", null: false
    t.string "make", null: false
    t.integer "mileage", default: 0, null: false
    t.string "model", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["customer_id"], name: "index_vehicles_on_customer_id"
    t.index ["license_plate"], name: "index_vehicles_on_license_plate", unique: true
    t.index ["status"], name: "index_vehicles_on_status"
  end

  add_foreign_key "vehicles", "customers"
end
