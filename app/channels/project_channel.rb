class ProjectChannel < ApplicationCable::Channel
  def follow(data)
#    project = Project.find(data['project_id'])
    stream_for "project"
#    DirtyStatusChangeJob.perform_later project
  end

  def unfollow
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

end
