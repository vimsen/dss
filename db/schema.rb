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

ActiveRecord::Schema.define(version: 20161222143818) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ancillary_services_data", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "purchased_volumes"
    t.float    "sold_volumes"
    t.float    "min_purchasing_price"
    t.float    "average_purchasing_price"
    t.float    "max_selling_price"
    t.float    "average_selling_price"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bids", force: :cascade do |t|
    t.date     "date"
    t.integer  "mo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "status"
  end

  add_index "bids", ["status"], name: "index_bids_on_status", using: :btree

  create_table "building_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clusterings", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clusters", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configurations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "algorithm_id"
    t.text     "params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "configurations", ["user_id"], name: "index_configurations_on_user_id", using: :btree

  create_table "connection_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_points", force: :cascade do |t|
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

  add_index "data_points", ["prosumer_id"], name: "index_data_points_on_prosumer_id", using: :btree
  add_index "data_points", ["timestamp", "prosumer_id", "interval_id"], name: "index_data_points_on_timestamp_and_prosumer_id_and_interval_id", unique: true, using: :btree

  create_table "day_ahead_energy_demands", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "demand"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "day_ahead_energy_prices", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "price"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "day_ahead_energy_volumes", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "purchases"
    t.float    "sales"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "day_ahead_hours", force: :cascade do |t|
    t.integer  "day_ahead_id"
    t.integer  "time"
    t.float    "production"
    t.float    "consumption"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "day_ahead_hours", ["day_ahead_id"], name: "index_day_ahead_hours_on_day_ahead_id", using: :btree

  create_table "day_aheads", force: :cascade do |t|
    t.integer  "prosumer_id"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "day_aheads", ["prosumer_id"], name: "index_day_aheads_on_prosumer_id", using: :btree

  create_table "demand_response_prosumers", force: :cascade do |t|
    t.integer  "demand_response_id"
    t.integer  "prosumer_id"
    t.integer  "drp_type"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "demand_response_prosumers", ["demand_response_id"], name: "index_demand_response_prosumers_on_demand_response_id", using: :btree
  add_index "demand_response_prosumers", ["prosumer_id"], name: "index_demand_response_prosumers_on_prosumer_id", using: :btree

  create_table "demand_responses", force: :cascade do |t|
    t.integer  "interval_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "plan_id"
    t.string   "feeder_id"
    t.string   "issuer"
    t.integer  "prosumer_category_id"
    t.integer  "event_type"
  end

  add_index "demand_responses", ["interval_id"], name: "index_demand_responses_on_interval_id", using: :btree
  add_index "demand_responses", ["prosumer_category_id"], name: "index_demand_responses_on_prosumer_category_id", using: :btree

  create_table "dr_actuals", force: :cascade do |t|
    t.integer  "prosumer_id"
    t.float    "volume"
    t.datetime "timestamp"
    t.integer  "demand_response_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "dr_actuals", ["demand_response_id"], name: "index_dr_actuals_on_demand_response_id", using: :btree
  add_index "dr_actuals", ["prosumer_id", "timestamp", "demand_response_id"], name: "pros_time_dr_index", unique: true, using: :btree
  add_index "dr_actuals", ["prosumer_id"], name: "index_dr_actuals_on_prosumer_id", using: :btree

  create_table "dr_planneds", force: :cascade do |t|
    t.integer  "prosumer_id"
    t.float    "volume"
    t.datetime "timestamp"
    t.integer  "demand_response_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "dr_planneds", ["demand_response_id"], name: "index_dr_planneds_on_demand_response_id", using: :btree
  add_index "dr_planneds", ["prosumer_id"], name: "index_dr_planneds_on_prosumer_id", using: :btree

  create_table "dr_targets", force: :cascade do |t|
    t.float    "volume"
    t.datetime "timestamp"
    t.integer  "demand_response_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "dr_targets", ["demand_response_id"], name: "index_dr_targets_on_demand_response_id", using: :btree

  create_table "energy_efficiency_certificates", force: :cascade do |t|
    t.datetime "date"
    t.string   "cert_type"
    t.float    "price_reference"
    t.float    "price_cumulative_average"
    t.float    "price_minimum"
    t.float    "price_maximum"
    t.float    "tee_traded"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "energy_type_prosumers", force: :cascade do |t|
    t.float    "power"
    t.integer  "energy_type_id"
    t.integer  "prosumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "energy_type_prosumers", ["energy_type_id"], name: "index_energy_type_prosumers_on_energy_type_id", using: :btree
  add_index "energy_type_prosumers", ["prosumer_id"], name: "index_energy_type_prosumers_on_prosumer_id", using: :btree

  create_table "energy_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forecasts", force: :cascade do |t|
    t.integer  "prosumer_id"
    t.integer  "interval_id"
    t.datetime "timestamp"
    t.datetime "forecast_time"
    t.float    "production"
    t.float    "consumption"
    t.float    "storage"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "forecast_type"
  end

  add_index "forecasts", ["interval_id"], name: "index_forecasts_on_interval_id", using: :btree
  add_index "forecasts", ["prosumer_id"], name: "index_forecasts_on_prosumer_id", using: :btree
  add_index "forecasts", ["timestamp", "prosumer_id", "interval_id", "forecast_time", "forecast_type"], name: "forecastsuniqueindex", unique: true, using: :btree

  create_table "green_certificates", force: :cascade do |t|
    t.datetime "date"
    t.string   "certificate_type"
    t.string   "reference_year"
    t.float    "traded_volumes"
    t.float    "price_reference"
    t.float    "price_minimum"
    t.float    "price_maximum"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instances", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "configuration_id"
    t.string   "results"
    t.string   "status"
    t.string   "reason"
    t.string   "instance_name"
    t.string   "worker"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_execution_time"
    t.integer  "priority_id",          default: 1
  end

  create_table "intervals", force: :cascade do |t|
    t.integer  "duration"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "intra_day_energy_prices", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "price"
    t.integer  "interval_id"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "intra_day_energy_volumes", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "purchases"
    t.float    "sales"
    t.integer  "region_id"
    t.integer  "interval_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_instances", force: :cascade do |t|
    t.integer  "instance_id"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "market_operators", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "market_regions", force: :cascade do |t|
    t.integer  "mo_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mb_provisional_total_data", force: :cascade do |t|
    t.date     "date"
    t.integer  "dayhour"
    t.float    "purchased_revoked"
    t.float    "purchased_not_revoked"
    t.float    "sold_revoked"
    t.float    "sold_not_revoked"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "meters", force: :cascade do |t|
    t.string   "mac"
    t.integer  "prosumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "meters", ["prosumer_id"], name: "index_meters_on_prosumer_id", using: :btree

  create_table "prosumer_categories", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "real_time"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "prosumers", force: :cascade do |t|
    t.string   "name"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cluster_id"
    t.string   "edms_id"
    t.integer  "building_type_id"
    t.integer  "connection_type_id"
    t.float    "location_x"
    t.float    "location_y"
    t.string   "feeder_id"
    t.integer  "prosumer_category_id"
  end

  add_index "prosumers", ["building_type_id"], name: "index_prosumers_on_building_type_id", using: :btree
  add_index "prosumers", ["connection_type_id"], name: "index_prosumers_on_connection_type_id", using: :btree
  add_index "prosumers", ["edms_id"], name: "index_prosumers_on_edms_id", unique: true, using: :btree
  add_index "prosumers", ["prosumer_category_id"], name: "index_prosumers_on_prosumer_category_id", using: :btree

  create_table "prosumers_temp_clusters", force: :cascade do |t|
    t.integer "prosumer_id"
    t.integer "temp_cluster_id"
  end

  add_index "prosumers_temp_clusters", ["prosumer_id", "temp_cluster_id"], name: "index_prosumers_temp_clusters_on_prosumer_id_and_temp_cluster", using: :btree

  create_table "prosumers_users", id: false, force: :cascade do |t|
    t.integer "prosumer_id"
    t.integer "user_id"
  end

  add_index "prosumers_users", ["prosumer_id", "user_id"], name: "index_prosumers_users_on_prosumer_id_and_user_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "sla_items", force: :cascade do |t|
    t.integer  "bid_id"
    t.datetime "timestamp"
    t.integer  "interval_id"
    t.float    "volume"
    t.float    "price"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sla_items", ["bid_id"], name: "index_sla_items_on_bid_id", using: :btree
  add_index "sla_items", ["interval_id"], name: "index_sla_items_on_interval_id", using: :btree
  add_index "sla_items", ["timestamp", "interval_id", "bid_id"], name: "index_sla_items_on_timestamp_and_interval_id_and_bid_id", unique: true, using: :btree

  create_table "targets", force: :cascade do |t|
    t.float    "volume"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "temp_clusters", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "clustering_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "temp_clusters", ["clustering_id"], name: "index_temp_clusters_on_clustering_id", using: :btree

  create_table "users", force: :cascade do |t|
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
    t.string   "authentication_token"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  add_foreign_key "configurations", "users"
  add_foreign_key "demand_response_prosumers", "demand_responses"
  add_foreign_key "demand_response_prosumers", "prosumers"
  add_foreign_key "demand_responses", "intervals"
  add_foreign_key "demand_responses", "prosumer_categories"
  add_foreign_key "dr_actuals", "demand_responses"
  add_foreign_key "dr_actuals", "prosumers"
  add_foreign_key "dr_planneds", "demand_responses"
  add_foreign_key "dr_planneds", "prosumers"
  add_foreign_key "dr_targets", "demand_responses"
  add_foreign_key "forecasts", "intervals"
  add_foreign_key "forecasts", "prosumers"
  add_foreign_key "prosumers", "prosumer_categories"
  add_foreign_key "sla_items", "bids"
  add_foreign_key "sla_items", "intervals"
end
