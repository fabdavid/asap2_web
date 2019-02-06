class ProjectBroadcastJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(project, step_id)
#   ProjectChannel.broadcast_to project,
#                               project_id: project.id,
#                               new_status: project.status_id
    ActionCable.server.broadcast "project_#{project.id}", {
      project_id: project.id,
      step_id: step_id,
      new_status: project.status_id,
      results: get_results(project, step_id)
    }
  end

  def get_results(project, step_id)
    step = Step.find(step_id)
    h_status = {}
    Status.all.map{|s| h_status[s.id]=s}

    h_res = {
      :h_statuses => h_status, 
      :url_base_callback => get_step_project_path(:key => project.key, :nolayout => 1, :step_id => step_id, :bla => 'test')
    }
   # parsing_status = nil
   # h_nber_analyses = nil
    js_cmds = []
    if step.name == 'parsing'
      if parsing_job_id = project.parsing_job_id
        parsing_job = Job.where(:id => parsing_job_id).first
        #        parsing_status=h_status[parsing_job.status_id].name
        h_res[:parsing_status_id] = parsing_job.status_id
      end
      #  js_cmds.push "var parsing_status='#{parsing_status}'"
     # js_cmds.push "$('li#step_#{step_id} span.step_status').html('<i class=\'#{h_status[parsing_job.status_id].icon_class}\'></i>')"
     
    else ## update the nbers
      obj = step.obj_name.classify.constantize
      [1, 2, 3, 4, 5].each do |status_id|
       # h_nber_analyses[status_id] = 
        tmp_nber = obj.where(:status_id => status_id).count()
     #   js_cmds.push "$('li#step_#{step_id} span.nber_#{h_status[status_id].name}').html(#{tmp_nber})"
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
    ProjectsController.render(
                            :partial => 'live_upd',
                             :locals => {
                               :project => project,
                               :js_cmds => js_cmds 
                             })
                             
  end

end
