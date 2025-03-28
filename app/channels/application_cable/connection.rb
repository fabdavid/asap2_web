module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
#      puts "[DEBUG] WebSocket connection established"
    end

     def disconnect
#      puts "[DEBUG] WebSocket connection closed"
     end
     
  end
end
