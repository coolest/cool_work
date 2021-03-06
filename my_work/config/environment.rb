# Be sure to restart your server when you modify this file.
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '1.99.0' unless defined? RAILS_GEM_VERSION
RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION
ORDER_MIN_PRICE = 30
# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :session_key => '_myfreshshirt_session',
    :secret      => '13827a10794a8af1f3dfce3eb5f425b4'
  }

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :active_resource ]

  # Only load the plugins named here, in the order given. By default, all plugins in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named.
  config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = [:location_observer]
  config.action_mailer.raise_delivery_errors = true


end
require "will_paginate"
require 'smtp_tls'

ActionMailer::Base.delivery_method = :sendmail
#ActionMailer::Base.perform_deliveries = true  
#ActionMailer::Base.default_charset = "utf-8"
#ActionMailer::Base.default_content_type = "text/html"

# ActionMailer::Base.smtp_settings = {
#    :enable_starttls_auto => true,  #this is the important shit!
#     :address        => 'smtp.sendgrid.net',
#    :port           => 587,
#    :domain         => 'myfreshshirt.com',
#    :authentication => :plain,
#   :user_name      => 'edutton@myfreshshirt.com',
#    :password       => 'muffin7979'
# 
# }

ActionView::live_validations = true
#ExceptionNotifier.exception_recipients = %w(ilan@genrealty.com Erin.Dutton@maesa.com edutton@4g-management.com)
#ExceptionNotifier.exception_recipients = %w(jayesh@systematixtechnocrates.com Erin.Dutton@maesa.com edutton@4g-management.com)
ExceptionNotification::Notifier.exception_recipients = %w()
ExceptionNotification::Notifier.sender_address = %("Application Error" <exceptions@practical.cc>)
ExceptionNotification::Notifier.email_prefix = "[myfreshshirt] "
