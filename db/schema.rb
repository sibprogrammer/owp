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

ActiveRecord::Schema.define(:version => 20100228060843) do

  create_table "event_logs", :force => true do |t|
    t.integer  "level"
    t.string   "message"
    t.string   "params"
    t.datetime "created_at"
  end

  create_table "hardware_servers", :force => true do |t|
    t.string "host"
    t.string "auth_key"
    t.string "description"
    t.string "default_os_template"
    t.string "templates_dir"
  end

  add_index "hardware_servers", ["host"], :name => "index_hardware_servers_on_host", :unique => true

  create_table "os_templates", :force => true do |t|
    t.string  "name"
    t.integer "hardware_server_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.integer  "role_type",                               :default => 1
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "virtual_servers", :force => true do |t|
    t.integer "identity"
    t.string  "ip_address"
    t.string  "host_name"
    t.string  "state",              :limit => 20
    t.integer "hardware_server_id"
    t.boolean "start_on_boot",                    :default => true
    t.string  "nameserver"
    t.string  "search_domain"
    t.integer "diskspace",                        :default => 1024
    t.integer "memory",                           :default => 256
    t.string  "orig_os_template"
    t.integer "user_id",                          :default => 0
  end

end
