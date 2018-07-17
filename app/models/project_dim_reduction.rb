class ProjectDimReduction < ApplicationRecord

  belongs_to :status
  belongs_to :user
  belongs_to :project
  belongs_to :dim_reduction
#  include Basic


  NewVisualization = Struct.new(:pdr, :sub_step) do
    def perform
      pdr.run(sub_step)
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 4).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        pdr.update_attributes(:status_id => 4)
      end
    end
  end

  def run sub_step
#  require 'basic.rb'

    project = self.project
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    visualization_dir = project_dir + 'visualization' + self.dim_reduction.name

    ### empty directory                                                                                                                                                     \
    puts "empty directory #{visualization_dir}..."
    #list_files_to_keep = ["timeseries.txt"]
    Dir.new(visualization_dir).entries.select{|e| !e.match(/^\./)}.each do |e|
      puts "Deleting file #{e}..."
      File.delete(visualization_dir+ e)
    end

    
    h_cmds = {
      'visualization.R' => "Rscript --vanilla lib/visualization.R",
      'zifa.py' => "export MKL_NUM_THREADS=4 && export NUMEXPR_NUM_THREADS=4 && export OMP_NUM_THREADS=4 && python lib/zifa.py",
 #     'heatmap.R' => "Rscript --vanilla --max-ppsize=500000 lib/heatmap.R",
 #     'correlation.R' => "rails --trace create_correlation[#{self.id}]"
    }
    
    start_time = Time.now
    self.update_attributes(:status_id => 2)
    project_step = ProjectStep.where(:project_id => project.id, :step_id => 4).first
    project_step.update_attributes(:status_id => 2) if project_step.status_id != 2

   
    dr = self.dim_reduction
   
    cmd = ''

    output_json = visualization_dir + 'output.json'
    if dr.id < 5
#       output_json = visualization_dir + 'output.json'
      h_parameters = JSON.parse(self.attrs_json)
      list_p = []
      list_attrs = JSON.parse(dr.attrs_json)
      
      list_attrs.reject{|e| e['not_in_cmd_line']}.each do |attr|
        list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
      end    
      
      cmd = ([h_cmds[dr.program], (project_dir + 'normalization' + 'output.tab'), visualization_dir, dr.name] + list_p).join(" ")

    elsif dr.id == 5

#      output_json = visualization_dir + 'output.heatmap.json'
      cmd = "rails create_heatmap[#{self.id}]"
    

    elsif dr.id ==6
      
        cmd = "rails create_correlation[#{self.id}]"
      
    elsif dr.id ==7
      
      ### trajectory using sub_step param
        cmd = "rails create_trajectory[#{self.id}]"

    end
    
    queue = dr.speed_id || 1    

    #cmd, project, step_id, output_file, output_json
    Basic.run_job(logger, cmd, project, self, 4, output_json, output_json, queue, self.job_id, self.user)
    
    ### update duration                                                           
    #start_time, project, step_id, o, output_file, output_json
    Basic.finish_step(logger, start_time, project, 4, self, output_json, output_json)

    running_pdrs = self.project.project_dim_reductions.select{|e| e.status_id == 2}
    successful_pdrs = self.project.project_dim_reductions.select{|e| e.status_id == 3}
    #   project.update_attributes(:status_id => 3) if successful_pdrs.size > 2
    
    if running_pdrs.size == 0 
      status_id = 3
      status_id = 4 if successful_pdrs.size == 0
      max_duration = successful_pdrs.map{|pdr| pdr.duration}.max
      ##refresh project_step
      project_step = ProjectStep.where(:project_id => project.id, :step_id => 4).first
      if !(project_step.status_id == nil and status_id == 4)  ## condition to prevent to update project_step when a job is killed when an earlier step is restarted (necessary if the kill is slower than the update of the ps.status to nil)
        self.project.update_attributes(:duration => max_duration, :status_id => status_id)
        project_step.update_attributes(:status_id => status_id)
      end
    end
  end
#  end

end
