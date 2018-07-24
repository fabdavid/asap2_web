class ProjectStatusBroadcastJob < ApplicationJob
  queue_as :default

  def perform(project)
   ProjectChannel.broadcast_to project,
                               project_id: project.id,
                               new_status: project.status_id
  end

end