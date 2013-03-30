RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')
require 'validations'

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'
end

ActionController::Base.param_parsers.delete(Mime::XML)

PRODUCT_NAME = 'OpenVZ Web Panel'
PRODUCT_VERSION = '2.4'

Watchdog = WatchdogClient.new unless defined? WATCHDOG_DAEMON
