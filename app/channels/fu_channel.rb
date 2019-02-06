class FuChannel < ApplicationCable::Channel
  def follow(data)
    fu = Fu.find(data['fu_id'])
    stream_from "fu_#{fu.id}"
#    DirtyStatusChangeJob.perform_later project                                                                                                         
  end

  def unfollow
    # Any cleanup needed when channel is unsubscribed                                                                                                   
    stop_all_streams
  end

end
