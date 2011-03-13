# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_owp_session',
    :secret      => 'de4d2a8a66ed013966673a0633d8153f8290d018efd9e5c6d307291879c6b3b8d2b59e03d1466878e7c89c217836c618598ecfbb911b881d42732d95354dd774'
  }
end

PRODUCT_NAME = 'OpenVZ Web Panel'
PRODUCT_VERSION = '2.0'

Watchdog = WatchdogClient.new unless defined? WATCHDOG_DAEMON
