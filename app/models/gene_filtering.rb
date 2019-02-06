class GeneFiltering < ApplicationRecord

  belongs_to :filter_method

  NewGeneFiltering = Struct.new(:gene_filtering) do
    def perform
      cluster.run
    end
    
    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        step = Step.where(:name => 'gene_filtering').first
        project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        cluster.update_attributes(:status_id => 4)
      end
    end
  end
  
  
  def run
    require 'basic'
    logger.debug("BLA!!!!!")
    start_time = Time.now
    self.update_attributes(:status_id => 2)
    project_step = ProjectStep.where(:project_id => self.id, :step_id => 2).first
    project_step.update_attributes(:status_id => 2)

    require "csv"

    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
    output_dir = project_dir + 'gene_filtering' + self.id.to_s

    FileUtils.rm_r output_dir if File.exist?(output_dir)

    if self.filter_method_id

      Dir.mkdir(output_dir) if !File.exists?(output_dir)

      filter_method = FilterMethod.find(self.filter_method_id)
      list_p = []
      h_parameters = JSON.parse(self.filter_method_attrs_json)
      list_attrs = JSON.parse(filter_method.attrs_json)

      list_attrs.reject{|e| e['not_in_cmd_line']}.each do |attr|
        list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
      end

      ercc_file = nil
      ercc_filename = project_dir + 'parsing' + "ercc.tab"
      ercc_file = ercc_filename if h_parameters['ercc_file_exists']

      #    logger.debug("H_PARAMETERS: " + h_parameters.to_json)                     
      #    logger.debug("LIST_ATTRS: " + list_attrs.to_json)                                                                                                                                                 
      log_file = project_dir + 'filtering' + "output.log"
      err_file = project_dir + 'filtering' + "output.err"
      output_file = output_dir + 'output.tab'
      output_json = output_dir + 'output.json'

      cmd = ["#{APP_CONFIG[:docker_call]}" + " '" + "Rscript --vanilla /srv/filtering.R",  project_dir + 'parsing' + 'output.tab', output_dir, filter_method.name, list_p.join(' '), ercc_file, "1> #{log_file} 2> #{err_file}", "'"].compact.join(" ")
      logger.debug "CMD: #{cmd.to_json}"
      
      queue = filter_method.speed_id || 1
      
      job = Basic.run_job(logger, cmd, self, self, 2, output_file, output_json, queue, self.filtering_job_id, self.user)
      
      if File.exists?(output_file)
        update_not_found_genes(output_dir, project_dir + "parsing")
      end

      #    ## write result files to download                                                                                                                                                                      #    write_download_file('filtering')                                                                                                                                                                  
      gene_names_file = project_dir + 'parsing' + 'gene_names.json'
      cmd = "#{APP_CONFIG[:docker_call]} -c 'java -jar /srv/ASAP.jar -T CreateDLFile -f #{output_file} -j #{gene_names_file} -o #{output_dir + 'dl_output.tab'}'"
      logger.debug("CMD: " + cmd)
      `#{cmd}`
    else

      File.symlink project_dir + 'parsing', output_dir
      
    end
    
    ## write result files to download                                                                                          
    #    write_download_file('filtering')                                                                                                                                                                  
    ### update duration                                                                                                                                                                                    
    if self.filter_method_id
      Basic.finish_step(logger, start_time, self, 2, self, output_file, output_json)
    else
      project_step.update_attributes(:status_id => 3)
      self.update_attributes(:duration => Time.now - start_time, :status_id => 3)
    end
    
  end
  
end
