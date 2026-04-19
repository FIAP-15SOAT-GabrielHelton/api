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

ActiveRecord::Schema[8.1].define(version: 2026_04_19_222454) do
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

  create_table "inventory_items", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "minimum_quantity", default: 0, null: false
    t.string "name", null: false
    t.integer "quantity", default: 0, null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_inventory_items_on_active"
    t.index ["code"], name: "index_inventory_items_on_code", unique: true
  end

  create_table "line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "item_type", null: false
    t.string "name_snapshot", null: false
    t.integer "price_snapshot_cents", null: false
    t.integer "quantity", null: false
    t.bigint "reference_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["item_type"], name: "index_line_items_on_item_type"
    t.index ["work_order_id"], name: "index_line_items_on_work_order_id"
  end

  create_table "quote_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "quantity", null: false
    t.bigint "quote_id", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id"], name: "index_quote_line_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["status"], name: "index_quotes_on_status"
    t.index ["work_order_id"], name: "index_quotes_on_work_order_id", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "base_price_cents", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "estimated_duration_minutes", default: 0, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_services_on_name", unique: true
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

  create_table "work_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.bigint "mechanic_id"
    t.text "problem_description", null: false
    t.string "protocol", null: false
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["customer_id"], name: "index_work_orders_on_customer_id"
    t.index ["protocol"], name: "index_work_orders_on_protocol", unique: true
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["vehicle_id"], name: "index_work_orders_on_vehicle_id"
  end

  add_foreign_key "line_items", "work_orders"
  add_foreign_key "quote_line_items", "quotes"
  add_foreign_key "quotes", "work_orders"
  add_foreign_key "vehicles", "customers"
  add_foreign_key "work_orders", "customers"
  add_foreign_key "work_orders", "vehicles"
end
