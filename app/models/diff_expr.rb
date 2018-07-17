class DiffExpr < ApplicationRecord

  belongs_to :diff_expr_method
  belongs_to :project
#  belongs_to :step
  has_many :gene_enrichments
  belongs_to :status
  belongs_to :job
  belongs_to :user

  NewDiffExpr = Struct.new(:diff_expr) do
    def perform
      diff_expr.run
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 6).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        diff_expr.update_attributes(:status_id => 4)
      end
    end
  end

  
  def run
    require 'basic.rb'

    project = self.project
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    de_dir = project_dir + 'de'
    Dir.mkdir de_dir if !File.exist?(de_dir)
    de_dir += self.id.to_s
    Dir.mkdir de_dir if !File.exist?(de_dir)
    
    h_cmds = {
      'de.R' => "Rscript --vanilla lib/de.R"
      #     'clustering.R' => "Rscript --vanilla lib/clustering.R",
      #     'localRscript clustering.R' => "/home/rvmuser/R-3.3.1/bin/Rscript --vanilla lib/clustering.R"
    }
    
    start_time = Time.now
    project_step = ProjectStep.where(:project_id => project.id, :step_id => 6).first
    project_step.update_attributes(:status_id => 2) if project_step.status_id !=2

    project.update_attributes(:status_id => 2) if project.status_id !=2
    self.update_attributes(:status_id => 2)
    
    de_method = self.diff_expr_method
    list_p = []
    h_parameters = JSON.parse(self.attrs_json)
    list_attrs = JSON.parse(de_method.attrs_json)
    
    list_attrs.reject{|e| e['not_in_cmd_line'] or e['obsolete']}.each do |attr|
      list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
    end
    
    h_tmp = {
      'original' => 'parsing',
      'filtered' => 'filtering',
      'normalized' => 'normalization'
    }
    
    input_file = project_dir + h_tmp[h_parameters['typefile']] + 'dl_output.tab'
    json_input_file = project_dir + h_tmp[h_parameters['typefile']] + 'output.json'
    #  if self.diff_exprid
    #    dr = DimReduction.where(:id => self.dim_reduction_id).first
    #    input_file = project_dir + 'visualization' + dr.name + 'output.json'
    #  else
    #    step = self.step
    #    input_file = project_dir + step.name + 'output.tab'
    #  end
    
    ### deal with is_log2                                                                                                                        

    group_file = 'null'
    group_filename = project_dir + 'parsing' + "group.tab"
    group_file = group_filename if h_parameters['batch_file']  #File.exist?(group_filename) and h_parameters[attr['name']]         

    selections = {}
    i=0
    [self.selection1_id, self.selection2_id].compact.each do |s_id|
      list_cells = File.read(project_dir + 'selections' + (s_id.to_s + '.txt')).split("\n")
      selections["group#{i+1}"] =list_cells
    i+=1
    end
    selection_file = de_dir + 'selections.json'
    File.open(selection_file, 'w') do |f|
      f.write(selections.to_json)
    end
    
    cmd = ([h_cmds[de_method.program], input_file, #json_input_file,
            de_dir, 
            de_method.name, group_file, selection_file, 1, 0] + list_p).join(" ") + " 1> #{de_dir}/output.log 2> #{de_dir}/output.err"
#    logger.debug("CMD: " + cmd)
    #    `#{cmd}`                                                                                                                                                                                                              
    #    launch_cmd(self, cmd)                                                                                                                                                                                                 
#    pid = spawn(cmd)
#    Basic::create_job(cmd, project)
#    Process.waitpid(pid)
    queue = de_method.speed_id || 1

    output_json = de_dir + 'output.up.json'
    output_json2 = de_dir + 'output.json'
    job = Basic.run_job(logger, cmd, project, self, 6, output_json, output_json2, queue, self.job_id, self.user)
    
    logger.debug("H_RES4: " +  project.key)

    ### filter results

    cmd = "rails filter_de_results[#{project.key},#{self.id}] --trace 2>&1 > log/filter_de_results.log"
    `#{cmd}`

    ### compute stats on filtered results

    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user.id.to_s + project.key
    h_res = {}
    ['up', 'down'].each do |e|
      filename = tmp_dir + "de" + self.id.to_s  + ("output." + e + "_filtered.json")
      if File.exists?(filename)
        h = JSON.parse(File.read(filename))
        first_col = h.keys.first
        h_res[('nber_' + e + '_genes').intern]=h[first_col].size
      end
    end

    json_file = tmp_dir + "de" + self.id.to_s  + "output.json"
    if File.exists?(json_file)
      h = JSON.parse(File.read(json_file))
      if h and h['displayed_error']
        h_res[:error]=h['displayed_error']
      end
    end

    self.update_attributes(h_res)
    
    Basic.finish_step(logger, start_time, project, 6, self, output_json, output_json2)
    if project.diff_exprs.select{|c| c.status_id == 3}.size > 0
      project_step.update_attributes(:status_id => 3)
    end

  end
end
