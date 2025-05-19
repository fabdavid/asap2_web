Rails.application.configure do
  # Settings specified here will take precedence over those
  # in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  #  config.action_cable.mount_path = "/cable"
  # Do not eager load code on boot.
  config.eager_load = false

  config.action_cable.logger = Logger.new(STDOUT)

  # Tell Rails to trust the proxy headers, including X-Forwarded-Proto
  #config.action_dispatch.trusted_proxies = ['127.0.0.1', '::1', '128.178.219.230']  # Ensure that the remote Nginx IP is included here
  
  # Make sure Rails redirects HTTPS URLs correctly (force_ssl is off for dev)
  #config.force_ssl = false  # Don't enforce SSL for all requests in dev
  
  # Rails should trust the X-Forwarded-Proto header for SSL redirection
  #config.ssl_options = {
  #    redirect: { 
  #    exclude: ->(request) { request.protocol == 'http://' } 
  #  }
  #}
  
  # Show full error reports.
  config.consider_all_requests_local = false # true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.serve_static_assets = true
  config.public_file_server.enabled = true
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  
  # Store uploaded files on the local file system
  # (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: 'asap.epfl.ch'} # 'localhost', port: 3000 }
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false
  # config.assets.compile = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

#  uglifier = Uglifier.new output: { comments: :none }
#  config.assets.js_compressor = uglifier
#  config.assets.css_compressor = :sass

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
