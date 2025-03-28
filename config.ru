# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

#puts "[DEBUG] Starting Puma with config.ru"
# Mount ActionCable server at /websocket
map '/websocket' do
  run ActionCable.server
end

run Rails.application



