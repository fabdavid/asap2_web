class Cluster < ApplicationRecord
  
  belongs_to :cluster_method
  belongs_to :project
  belongs_to :dim_reduction
  belongs_to :step
  belongs_to :status
  belongs_to :job
  belongs_to :user

  has_many :selections

    NewClustering = Struct.new(:cluster) do
    def perform
      cluster.run
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 5).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        cluster.update_attributes(:status_id => 4)
      end
    end
  end


  def run
    require 'basic.rb'
    
    project = self.project    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    clustering_dir = project_dir + 'clustering'
    Dir.mkdir clustering_dir if !File.exist?(clustering_dir)
    clustering_dir += self.id.to_s
    Dir.mkdir clustering_dir if !File.exist?(clustering_dir)

    h_cmds = {
      'clustering.R' => "Rscript --vanilla lib/clustering.R",
      'localRscript clustering.R' => "Rscript --vanilla lib/clustering.R"
    }

    start_time = Time.now
    project_step = ProjectStep.where(:project_id => project.id, :step_id => 5).first
    project_step.update_attributes(:status_id => 2) if project_step.status_id !=2
    
    project.update_attributes(:status_id => 2) if project.status_id !=2
    self.update_attributes(:status_id => 2)
    
    cm = self.cluster_method
    list_p = []
    h_parameters = JSON.parse(self.attrs_json)
    list_attrs = JSON.parse(cm.attrs_json)
    list_attrs.reject{|e| e['not_in_cmd_line']}.each do |attr|
      h_parameters[attr['name']] = '0' if (attr['name'] == 'nbclust' and  h_parameters[attr['name']] == '' )
      list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
    end

    input_file = ''
    if self.dim_reduction_id
      dr = DimReduction.where(:id => self.dim_reduction_id).first
      input_file = project_dir + 'visualization' + dr.name + 'output.json'
    else
      step = self.step
      input_file = project_dir + step.name + 'output.tab'
    end
    ### deal with is_log2
    
    cmd = ([h_cmds[cm.program], input_file, clustering_dir, cm.name] + list_p).join(" ") + " 1> #{project_dir + 'clustering' + "output.log"} 2> #{project_dir + 'clustering' + "output.err"}"

    #    logger.debug("CMD: " + cmd)
    
    queue = cm.speed_id || 1
    
    #    pid = spawn(cmd)
    #    Basic::create_job(cmd, project)
    #    Process.waitpid(pid)
    
    output_json = clustering_dir + "output.json"
    job = Basic.run_job(logger, cmd, project, self, 5, output_json, output_json, queue, self.job_id, self.user)
    
    #    if stopped == false
    
    h_res = {}
    
    result_file = project_dir + "clustering" + self.id.to_s  + "output.json"
    if File.exist?(result_file)
      h = JSON.parse(File.read(result_file))

      ### fix waiting Vincent is back from holidays (a dot is added to cell name in clustering.R)######################
      #      new_h_clusters={}
      #      list_keys_to_delete =[]
      #      h['clusters'].each_key do |k|
      #        if (m = k.match(/Cell\.(\d+)/))                                                                                                                
      #          new_k = "Cell #{m[1]}"
      #          new_h_clusters[new_k]=h['clusters'][k]
      #          list_keys_to_delete.push k
      #        end
      #      end
      #      new_h_clusters.each_key do |k|
      #        h['clusters'][k] = new_h_clusters[k]        
      #      end
      #      list_keys_to_delete.each do |k|
      #        h['clusters'].delete(k)
      #      end
      #      File.open(result_file, 'w') do |f|
      #        f.write(h.to_json)
      #      end
      #################################

      # h_res[:error]=h['displayed_error']
        if h and h['displayed_error']
          h_res[:error]=h['displayed_error']
        end
      end
    
    
    self.update_attributes(h_res)
    
      
      
      #    duration =  Time.now - start_time
      #    self.update_attributes(:duration => duration, :status_id => 3)
      #    project.update_attributes(:duration => duration, :status_id => 3)
      #    project_step.update_attributes(:status_id => 3)
      Basic.finish_step(logger, start_time, project, 5, self, output_json, output_json)
      if project.clusters.select{|c| c.status_id == 3}.size > 0
        project_step.update_attributes(:status_id => 3)
      end
    end
#  end

end
