# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121123114349) do

  create_table "clients", :force => true do |t|
    t.string  "email"
    t.string  "name"
    t.integer "market_client_id"
    t.string  "password"
    t.string  "api_key"
    t.integer "user_id"
  end

  add_index "clients", ["api_key"], :name => "index_clients_on_api_key"
  add_index "clients", ["user_id"], :name => "index_clients_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "location_categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "location_media", :force => true do |t|
    t.integer "medium_id",   :null => false
    t.integer "location_id", :null => false
  end

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.text     "full_description"
    t.float    "lat"
    t.float    "lng"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country"
    t.string   "city"
    t.string   "comment"
    t.text     "short_description"
    t.string   "address"
    t.string   "phone"
    t.string   "website"
    t.string   "email"
    t.string   "opening_hours"
    t.string   "entrance_fee"
    t.string   "nearest_transport"
    t.string   "thumbnail"
    t.string   "thumbnail_content_type"
    t.string   "street"
    t.string   "building"
    t.integer  "user_id",                :default => 1
    t.boolean  "is_draft",               :default => false
  end

  add_index "locations", ["user_id"], :name => "index_locations_on_user_id"

  create_table "media", :force => true do |t|
    t.string   "name",                                   :null => false
    t.text     "credits"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.string   "attachment_file_size"
    t.string   "type",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_fingerprint"
    t.string   "country",                                :null => false
    t.string   "city"
    t.integer  "user_id",                 :default => 1
  end

  add_index "media", ["country", "city"], :name => "index_media_on_country_and_city"
  add_index "media", ["country"], :name => "index_media_on_country"
  add_index "media", ["user_id"], :name => "index_media_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "tour_locations", :force => true do |t|
    t.integer  "tour_id",     :null => false
    t.integer  "location_id", :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tour_packages", :force => true do |t|
    t.integer  "tour_id"
    t.integer  "version"
    t.float    "south"
    t.float    "east"
    t.float    "north"
    t.float    "west"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "city"
    t.string   "tour_name"
    t.integer  "locations_count"
    t.string   "country"
    t.integer  "platform_id",     :default => 1, :null => false
  end

  add_index "tour_packages", ["platform_id"], :name => "index_tour_packages_on_platform_id"

  create_table "tour_ubertours", :force => true do |t|
    t.integer "tour_id"
    t.integer "ubertour_id"
    t.integer "position"
  end

  add_index "tour_ubertours", ["tour_id", "ubertour_id"], :name => "index_tour_ubertours_on_tour_id_and_ubertour_id"

  create_table "tours", :force => true do |t|
    t.string   "name"
    t.string   "city"
    t.string   "country"
    t.text     "overview"
    t.string   "info"
    t.string   "thumbnail_file_name"
    t.string   "thumbnail_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state"
    t.integer  "build_id"
    t.string   "build_message"
    t.datetime "last_built_at"
    t.boolean  "last_build_failed"
    t.integer  "length_in_minutes"
    t.integer  "length_in_km"
    t.integer  "user_id"
    t.boolean  "is_ubertour",         :default => false
    t.string   "ubertour_route_type", :default => "foot"
    t.string   "pob_categories_ids"
  end

  add_index "tours", ["user_id", "is_ubertour"], :name => "index_tours_on_user_id_and_is_ubertour"

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",        :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",        :null => false
    t.string   "password_salt",                       :default => "",        :null => false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login"
    t.string   "role",                                :default => "regular"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
