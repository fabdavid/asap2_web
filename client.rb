require 'byebug'
require 'action_cable_client'

puts "Process: #{Process.pid}"

100_000.times do |i|
  EventMachine.run do
    uri = "ws://localhost:3001/cable"
    client = ActionCableClient.new(uri, 'ChatChannel')

    # the connected callback is required, as it triggers
    # the actual subscribing to the channel
    client.connected do
      puts "#{i} Client connected"
    end

    client.subscribed do
      puts "#{i} Client subscribed"
    end

    client.received do |msg|
      puts "#{i} Client received: #{msg}"
      EM::stop_event_loop
    end

    client.errored do |msg|
      puts "Client errored: #{msg}"
    end

    client.disconnected do
      puts "#{i} Client disconnected"
      puts
    end
  end
end
