class ProjectBroadcastJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(project_id, step_id)
#   ProjectChannel.broadcast_to project,
#                               project_id: project.id,
#                               new_status: project.status_id
    project = Project.find(project_id)
#    h_data = {:reload_project => 1}
#    if step_id
    h_data = get_results(project, step_id)
    h_data.merge!({:project_id => project.id, :step_id => step_id, :new_status => project.status_id})
#    end
    ActionCable.server.broadcast "project_#{project.id}", h_data
#    ActionCable.server.broadcast "project", h_data 
#{
#      project_id: project.id,
#      step_id: step_id,
#      new_status: project.status_id,
#      results: get_results(project, step_id)
#    }
  end

  def get_results(project, step_id)
    step = Step.find(step_id)
    h_status = {}
    Status.all.map{|s| h_status[s.id]=s}
#    summary_step = Step.where(:version_id => project.version_id, :name => 'summary').first
    asap_docker_image = Basic.get_asap_docker(project.version)
    summary_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'summary').first

    h_res = {
      :step_name => step.name,
      :step => step,
      :h_nber_analyses => {},
      #      :h_statuses_json => h_status.to_json, 
      #      :summary_step_id => Step.find_by_name("summary").id,
      :url_base_callback => get_step_project_path(:key => project.key, :nolayout => 1, :step_id => step_id),
      :url_step_header_callback => get_step_header_project_path(:key => project.key, :nolayout => 1, :step_id => step_id),
      :url_dim_reduction_callback => get_step_project_path(:key => project.key, :nolayout => 1, :step_id => step_id, :partial => 'dim_reduction_form'), #get_dim_reduction_form_project_path(:key => project.key)
      :summary_step_id => summary_step.id
    }

   # parsing_status = nil
   # h_nber_analyses = nil

    js_cmds = []
    if step.name == 'parsing'
      if parsing_job_id = project.parsing_job_id
        parsing_job = Run.where(:project_id => project.id, :step_id => step_id).first
        h_res[:parsing_status_id] = parsing_job.status_id #(parsing_job) ? parsing_job.status_id : 1
      end
    else ## update the nbers
      [1, 2, 3, 4, 5].each do |status_id|
        tmp_nber = Run.where(:project_id => project.id, :step_id => step_id, :status_id => status_id).count
        h_res[:h_nber_analyses][status_id] = tmp_nber
      end
    end

    #    h_nber_analyses = {}
    #    step_names = ['filtering', 'normalization', 'imputation', 'visualization', 'clustering, ''de', 'gene_enrichment']
    #    steps = Step.where(:name => step_names).all.each do |step|
    #      obj = step.obj_name.classify.constantize
    #      [1, 2, 3, 4, 5].each do |status_id|
    #      obj.where(:status_id => status_id).count()
    #    end
 
    ## check if need to get step
    
#   return js_cmds.join "\n"
    return h_res
    #    ProjectsController.render(
#                            :partial => 'live_upd',
#                             :locals => {
#                               :project => project,
#                               :js_cmds => js_cmds 
#                             })
                             
  end

end
