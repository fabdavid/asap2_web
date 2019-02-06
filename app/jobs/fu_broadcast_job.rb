class FuBroadcastJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(fu)
#   ProjectChannel.broadcast_to project,                                                                                                                
#                               project_id: project.id,                                                                                                 
#                               new_status: project.status_id                                                                                           
    ActionCable.server.broadcast "fu_#{fu.id}", {
      fu_id: fu.id,
      url_preparsing: preparsing_fu_path(fu),
      results: "Uploaded"
    }
  end
end
