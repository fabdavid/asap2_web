require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Asap2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.exceptions_app = self.routes

#    require_relative '../app/middleware/response_size_tracker'
    
#    config.autoload_paths += %W(#{Rails.root}/app/middleware)
    
#    puts "[DEBUG] ACTION_CABLE_FRONTEND_URL: #{ENV['ACTION_CABLE_FRONTEND_URL']}"
#    puts "[DEBUG] ACTION_CABLE_MOUNT_PATH: #{ENV['ACTION_CABLE_MOUNT_PATH']}"

    
    # Enable this to ensure Rails respects the protocol forwarded by your proxy
#    config.action_dispatch.trusted_proxies = ['0.0.0.0/0', '::/0']  # Trust all proxies (or restrict to your proxy's IP)
#    config.action_dispatch.ssl_redirect = true  # Automatically redirect HTTP to HTTPS
    
    # Allow Rails to use the X-Forwarded-Proto header to determine the correct protocol
#    config.action_controller.default_url_options = { protocol: 'https' }
#     config.action_controller.default_url_options = { host: 'asap.epfl.ch', protocol: 'https' }

#    config.hosts << "asap-old.epfl.ch"
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set up logging to be the same in all environments but control the level
    # through an environment variable.
#    config.action_dispatch.default_headers = {
#      'X-Frame-Options' => 'ALLOW-FROM http://net-kiosk.com',
#      'Access-Control-Allow-Origin' => 'https://gecftools.epfl.ch'
#    }
 #   config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

    config.log_level = ENV['LOG_LEVEL']

    config.middleware.delete Rack::Lock

    config.middleware.use Rack::Deflater
#    config.middleware.use ResponseSizeTracker
    
#    Rails.application.middleware.use Rack::Timeout
#    Rack::Timeout.timeout = 20  # seconds
    
    # Log to STDOUT because Docker expects all processes to log here. You could
    # then redirect logs to a third party service on your own such as systemd,
    # or a third party host such as Loggly, etc..
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.log_tags  = %i[subdomain uuid]
    config.logger    = ActiveSupport::TaggedLogging.new(logger)

    config.assets.paths << Rails.root.join("app", "assets", "fonts") 

    # Action mailer settings.
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              ENV['SMTP_ADDRESS'],
      port:                 ENV['SMTP_PORT'].to_i,
      #  domain:               ENV['SMTP_DOMAIN'],
      #  user_name:            ENV['SMTP_USERNAME'],
      #  password:             ENV['SMTP_PASSWORD'],
      #  authentication:       ENV['SMTP_AUTH'],
      enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true'
    }

   # config.action_mailer.default_url_options = {
      #   host: ENV['ACTION_MAILER_HOST']
     # :host => "mail.epfl.ch",
     # :port => 25
   # }
    config.action_mailer.default_options = {
      from: ENV['ACTION_MAILER_DEFAULT_FROM']
    }

    # Set Redis as the back-end for the cache.
    config.cache_store = :redis_store, ENV['REDIS_CACHE_URL']

    # Set Sidekiq as the back-end for Active Job.
    config.active_job.queue_adapter = :sidekiq
    config.active_job.queue_name_prefix =
      "#{ENV['ACTIVE_JOB_QUEUE_PREFIX']}_#{Rails.env}"

    config.action_cable_mount_path = ENV['ACTION_CABLE_MOUNT_PATH']
    # Action Cable setting to de-couple it from the main Rails process.
    config.action_cable.url = ENV['ACTION_CABLE_FRONTEND_URL']

    # Action Cable setting to allow connections from these domains.
    origins = ENV['ACTION_CABLE_ALLOWED_REQUEST_ORIGINS'].split(',')
    origins.map! { |url| /#{url}/ }
    config.action_cable.allowed_request_origins = origins
  end
end

# Show in-line form errors.
ActionView::Base.field_error_proc = proc do |html_tag, instance|
  if html_tag =~ /\<label/
    html_tag
  else
    errors = Array(instance.error_message).join(',')
    %(#{html_tag}<p class="validation-error"> #{errors}</p>).html_safe
  end
end
