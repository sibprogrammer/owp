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

ActiveRecord::Schema.define(:version => 20130223060327) do

  create_table "background_jobs", :force => true do |t|
    t.string  "description"
    t.string  "params"
    t.integer "status"
  end

  create_table "backups", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "size"
    t.integer "virtual_server_id"
  end

  create_table "bean_counters", :force => true do |t|
    t.string   "name"
    t.integer  "virtual_server_id"
    t.string   "held"
    t.string   "maxheld"
    t.string   "barrier"
    t.string   "limit"
    t.string   "failcnt"
    t.integer  "period_type"
    t.datetime "created_at"
    t.boolean  "alert",             :default => false
  end

  create_table "comments", :force => true do |t|
    t.text     "content"
    t.datetime "created_at"
    t.integer  "request_id"
    t.integer  "user_id"
  end

  create_table "event_logs", :force => true do |t|
    t.integer  "level"
    t.string   "message"
    t.string   "params"
    t.datetime "created_at"
    t.string   "ip_address"
  end

  create_table "hardware_servers", :force => true do |t|
    t.string  "host"
    t.string  "auth_key"
    t.string  "description"
    t.string  "default_os_template"
    t.string  "templates_dir"
    t.string  "default_server_template"
    t.string  "vzctl_version"
    t.integer "daemon_port",             :default => 7767
    t.string  "backups_dir"
    t.string  "ve_private"
    t.boolean "use_ssl",                 :default => false
    t.boolean "vswap",                   :default => false
  end

  add_index "hardware_servers", ["host"], :name => "index_hardware_servers_on_host", :unique => true

  create_table "ip_pools", :force => true do |t|
    t.string  "first_ip"
    t.string  "last_ip"
    t.integer "hardware_server_id"
  end

  create_table "os_templates", :force => true do |t|
    t.string  "name"
    t.integer "hardware_server_id"
    t.integer "size"
  end

  create_table "permissions", :force => true do |t|
    t.string "name"
  end

  create_table "permissions_roles", :id => false, :force => true do |t|
    t.integer "permission_id"
    t.integer "role_id"
  end

  create_table "requests", :force => true do |t|
    t.string   "subject"
    t.text     "content"
    t.boolean  "opened",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "roles", :force => true do |t|
    t.string  "name"
    t.boolean "built_in"
    t.integer "limit_backups"
  end

  create_table "server_templates", :force => true do |t|
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
    t.string   "email"
    t.string   "contact_name"
    t.boolean  "enabled",                                 :default => true
    t.integer  "role_id"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "virtual_servers", :force => true do |t|
    t.string  "identity"
    t.string  "ip_address"
    t.string  "host_name"
    t.string  "state",                :limit => 20
    t.integer "hardware_server_id"
    t.boolean "start_on_boot",                      :default => true
    t.string  "nameserver"
    t.string  "search_domain"
    t.integer "diskspace",                          :default => 1024
    t.integer "memory",                             :default => 256
    t.string  "orig_os_template"
    t.integer "user_id",                            :default => 0
    t.string  "orig_server_template"
    t.string  "description"
    t.integer "cpu_units"
    t.integer "cpu_limit"
    t.integer "cpus"
    t.date    "expiration_date"
    t.integer "vswap",                              :default => 0
    t.boolean "daily_backup",                       :default => false
  end

end
