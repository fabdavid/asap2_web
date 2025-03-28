#Rails.application.config.middleware.insert_before 0, Rack::Cors do
#  allow do
#    origins 'https://asap.epfl.ch'
#    resource '*',
#      headers: :any,
#      methods: [:get, :post, :options, :delete, :put],
#      credentials: true
#  end
#end
