class FuChannel < ApplicationCable::Channel
  def subscribed
      stream_from "fu_#{params[:fu_id]}"
  end

  def unfollow
    # Any cleanup needed when channel is unsubscribed                                                                                                   
    stop_all_streams
  end

end
