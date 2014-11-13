# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141113083033) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clusters", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_points", force: true do |t|
    t.integer  "prosumer_id"
    t.integer  "interval_id"
    t.datetime "timestamp"
    t.float    "production"
    t.float    "consumption"
    t.float    "storage"
    t.datetime "f_timestamp"
    t.float    "f_production"
    t.float    "f_consumption"
    t.float    "f_storage"
    t.float    "dr"
    t.float    "reliability"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "day_ahead_hours", force: true do |t|
    t.integer  "day_ahead_id"
    t.integer  "time"
    t.float    "production"
    t.float    "consumption"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "day_ahead_hours", ["day_ahead_id"], name: "index_day_ahead_hours_on_day_ahead_id", using: :btree

  create_table "day_aheads", force: true do |t|
    t.integer  "prosumer_id"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "day_aheads", ["prosumer_id"], name: "index_day_aheads_on_prosumer_id", using: :btree

  create_table "energy_type_prosumers", force: true do |t|
    t.float    "power"
    t.integer  "energy_type_id"
    t.integer  "prosumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "energy_type_prosumers", ["energy_type_id"], name: "index_energy_type_prosumers_on_energy_type_id", using: :btree
  add_index "energy_type_prosumers", ["prosumer_id"], name: "index_energy_type_prosumers_on_prosumer_id", using: :btree

  create_table "energy_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "intervals", force: true do |t|
    t.integer  "duration"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measurements", force: true do |t|
    t.datetime "timeslot"
    t.float    "power"
    t.integer  "prosumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prosumers", force: true do |t|
    t.string   "name"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cluster_id"
  end

  create_table "prosumers_users", id: false, force: true do |t|
    t.integer "prosumer_id"
    t.integer "user_id"
  end

  add_index "prosumers_users", ["prosumer_id", "user_id"], name: "index_prosumers_users_on_prosumer_id_and_user_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

end
