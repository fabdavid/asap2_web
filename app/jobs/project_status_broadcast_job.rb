class ProjectStatusBroadcastJob < ApplicationJob
  queue_as :default

  def perform(project)
#   ProjectChannel.broadcast_to project,
#                               project_id: project.id,
#                               new_status: project.status_id
    ActionCable.server.broadcast "project", {
      project_id: project.id,
      new_status: project.status_id,
      message: render_message(project)
    }
  end

  def render_message(project)
    return 'alert("bla")'
  end

end
