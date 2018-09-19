#Rack::Timeout.timeout = ENV.fetch('REQUEST_TIMEOUT') { 5 }.to_i
Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 35, wait_timeout: 60

