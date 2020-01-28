class ProjectChannel < ApplicationCable::Channel

#  def subscribed    
#    stream_from 'project'
#  end

  def subscribed #(data)
#  def follow(data) 
#    data = params
#    if data['project_id']
#      project = Project.find(data['project_id'])
      stream_from "project_#{params[:project_id]}"
#    stream_from "project"
#      sleep 5
#    end
    #    ProjectBroadcastJob.perform_later project, step_id
    #    DirtyStatusChangeJob.perform_later project
  end

  def unfollow
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

end
