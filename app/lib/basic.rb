module Basic

#class Basic

  class << self

    def safe_parse_json json, default
      h = default
      begin
        h = JSON.parse json
      rescue
      end
      return h
    end
        
    # Show the average system load of the past minute
    def machine_load
      load = 0.0
      if File.exists?("/proc/loadavg")
        File.open("/proc/loadavg", "r") do |file|
          @loaddata = file.read
        end
        
        load = @loaddata.split(/ /).first.to_f
      end
    
      return load
    end

    def relative_path project, path
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
  #    puts project_dir + " -- " + path
  #    return path.relative_path_from(project_dir)
      return path.to_s.gsub(/^#{project_dir}\//, "")
    end

    def get_std_method_attrs std_method, step
      
      h_global_params = JSON.parse(step.method_attrs_json)
      
      h_attrs = (std_method) ? JSON.parse(std_method.attrs_json) : {}
      ## complement attributes with global parameters - defined at the level of the step                                                      
      
      h_global_params.each_key do |k|
        h_attrs[k]={}
        h_global_params[k].each_key do |k2|
          h_attrs[k][k2] = h_global_params[k][k2]
        end
      end
      
      h_res = {
        :h_attrs => h_attrs,
        :h_global_params => h_global_params
      }

      return h_res
    end

    def create_upd_fo project_id, relative_filepath
      
   #   puts "project_id => #{project_id}, relative_filepath => #{relative_filepath}"
      t = relative_filepath.split("/")
      store_run = nil
      if t.size == 3
        store_run = Run.where(:id => t[1]).first
      else
        store_run = Run.joins("join steps on (step_id = steps.id)").where(:project_id => project_id, :steps => {:name => t[0]}).first
      end

      if store_run
        project = store_run.project
        
        h_fo = {
          :project_id => store_run.project_id,
          :run_id => store_run.id,
          :user_id => store_run.user_id,
          :filepath => relative_filepath,
          :ext => relative_filepath.split(".").last
        }
        fo = Fo.where(h_fo).first
        if !fo
          fo = Fo.new(h_fo)
          fo.save
        end
        
        project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
        filepath = project_dir + fo.filepath
        fo.update_attributes(:filesize => File.size(filepath))
      end

      return fo
    end
    
    def load_annot run, meta, relative_filepath, h_data_types
      
      #list_metadata.each do |meta|
      project = run.project
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    
  #    puts "BLAAAA: " + meta.to_json
      
      if annot = Annot.where(:project_id => run.project_id, :name => meta['name'], :run_id => run.id).first
        annot.destroy          
      end
      
      #      annot_path = meta['name']
      #      t =  meta['name'].split("/")
      #      annot_name = meta['name'].gsub(/(\/.{3}_attrs\/)/, '')

      #      relative_filepath = relative_path(project, filepath)

      # create or update fo
      fo = create_upd_fo(run.project_id, relative_filepath)

      # complete annotation details if data type is not defined      
      if !meta['type'] or !meta['dataset_size']
        ## get same annotation from parsing
        parsing_annot = Annot.where(:project_id => project.id, :name => meta['name']).first
        if parsing_annot
          meta["type"] = (dt = parsing_annot.data_type) ? dt.name : nil
          type_txt = (dt = parsing_annot.data_type) ? "-type #{dt.name}" : ""
        end
        loom_path = project_dir + relative_filepath
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -no-values -T ExtractMetadata -loom #{loom_path} #{type_txt} -meta #{meta['name']}"
     #   puts cmd
        res_json =`#{cmd}`
     #   puts res_json
        meta_compl = Basic.safe_parse_json(res_json, {})
#        begin
#          meta_compl = JSON.parse(res_json)
#        rescue
#        end
        list_p = ['nber_cols', 'nber_rows', 'dataset_size']
        list_p.push("categories") if meta["type"] == 'DISCRETE'
        list_p.each do |k|
          meta[k] = meta_compl[k] #if meta_compl[k]
        end
      end

      h_annot = {
        :project_id => run.project_id,
        :step_id => run.step_id,
        :run_id => run.id,
        :filepath => relative_filepath,
        :store_run_id => (fo) ? fo.run_id : nil,
        :headers_json => (meta['nber_rows'] and meta['nber_cols'] and meta['nber_rows'] > 0 and meta['nber_cols'] > 0 and meta['on'] != 'EXPRESSION_MATRIX') ? ((meta['headers']) ? meta['headers'].to_json : ((1 .. ((meta['on'] == 'GENE') ? meta['nber_cols'] : meta['nber_rows'])).map{|i| "Value #{i}"}.to_json)) : nil, 
        #  :fo_id => (fo) ? fo.id : nil,
        :name => meta['name'],
        :categories_json => (meta['categories']) ? meta['categories'].to_json : nil,
        :dim => (meta['on'] == 'EXPRESSION_MATRIX') ? 3 : ((meta['on'] == 'CELL') ? 1 : 2),
        :data_type_id => (dt = h_data_types[meta['type']]) ? dt.id : nil,
        :nber_cat => (meta['categories']) ? meta['categories'].size : nil,
        :nber_rows => meta['nber_rows'],
        :nber_cols => meta['nber_cols'],
        :mem_size => meta['dataset_size'],#(meta['nber_cols'] and  meta['nber_rows']) ? 4 * meta['nber_cols'] * meta['nber_rows'] : nil,
        :label => nil,
        :user_id => run.user_id
      }
      
      annot = Annot.new(h_annot)
      annot.save!
      return annot
      #end
      #list_res = JSON.parse(res) 
    end

    def get_project_step_details project, step_id
      #logger.debug("Get project_step details for " + project.key + " and step " + step_id)
      h_project_step = {}
      h_nber_runs = {}
      runs = Run.where(:project_id => project.id, :step_id => step_id).all
      runs.each do |run|
        h_nber_runs[run.status_id] ||= 0
        h_nber_runs[run.status_id] += 1
      end
      if runs.size == 0
         h_project_step[:status_id] = nil
      else
        [1, 3, 4, 2].each do |status_id|
          h_project_step[:status_id] = status_id if h_nber_runs[status_id] and h_nber_runs[status_id] > 0
        end
      end
      
      h_project_step[:nber_runs_json] = h_nber_runs.to_json
      
      return h_project_step

    end

    def upd_project_size project
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
      project.update_attributes(:disk_size => `du -s #{project_dir}`.split(/\s+/).first.to_i * 1000)
    end

    def upd_project_step project, step_id
      h_project_step =  Basic.get_project_step_details(project, step_id)
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step_id).first
      if project_step
        project_step.update_attributes(h_project_step)
      end
      # puts "PROJECT_STEP: " + project_step.to_json
      ### update project stats
      h_nber_runs = {}
      ProjectStep.where(:project_id => project.id).all.each do |ps|
        h_tmp = JSON.parse(ps.nber_runs_json)
        h_tmp.keys.map{|k| h_nber_runs[k]||=0; h_nber_runs[k] += h_tmp[k]}
      end
      # puts h_nber_runs.to_json
      project.update_attributes({:modified_at => Time.now, :nber_runs_json => h_nber_runs.to_json})
    end

    def save_run run
      run.save
     # h_active_run = run.as_json
     # h_active_run[:run_id]= run.id
     # h_active_run.delete(:id)
     # active_run = ActiveRun.new(h_active_run)
     # active_run.save!
    end

    def upd_run project, run, h_upd
      run.update_attributes(h_upd)
      flag_change_status = (h_upd[:status_id] and h_upd[:status_id] != run.status_id) ? true : false
    
      ### active run thingy....
      # max_try = 5 ###the active run might be not yet created
      # try = 0
      # while ( try < max_try and !run.active_run ) do 
      #   try+=1
      # end
      # if (active_run = run.active_run)
      #   #        if h_upd[:status_id] == 4
      #   #          active_run.delete          
      #   #        else
      #   active_run.update_attributes(h_upd)
      #   sleep(0.3)
      # end
      

      ### update project_step
      #if flag_change_status == true
      upd_project_step project, run.step_id
      #end

    end

    def set_run logger, h_p

      h_res = {}

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + h_p[:project].user_id.to_s + h_p[:project].key
      run = h_p[:run] #list_of_runs[run_i][0]
      p = h_p[:p] #list_of_runs[run_i][1]
 #     h_step_attrs = JSON.parse(run.step.attrs_json)

      docker_image = h_p[:h_cmd_params]['docker_image']
     # step = run.step
      step_dir = project_dir + h_p[:step].name
      Dir.mkdir step_dir if !File.exist? step_dir
      output_dir = (h_p[:step].multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      Dir.mkdir output_dir if !File.exist? output_dir
      
      h_attrs = JSON.parse(h_p[:run].attrs_json)
      
      h_var = {
        'user_id' => h_p[:project].user_id,
        'project_dir' => project_dir,        
        'output_dir' => output_dir, #project_dir + h_p[:step].name + run.id.to_s,
        'std_method_name' => h_p[:std_method].name,
        'step_tag' => h_p[:step].tag,
        'run_num' => run.num,
        'asap_data_docker_db_conn' => 'postgres:5434/asap2_data_v' + h_p[:project].version_id.to_s,
        'asap_data_direct_db_conn' => 'postgres:5433/asap2_data_v' + h_p[:project].version_id.to_s,
      }

      ###optional variables stored in 
      #['output_matrix_dataset'].each do |e|
      #  
      #end
      
      h_std_method_attrs = JSON.parse(h_p[:std_method].attrs_json)
      
      run_parents = []
      h_parent_runs = {}
      
      new_h_attrs = JSON.parse(run.attrs_json)
#      if gp = new_h_attrs['group_pairs']
#        new_h_attrs['group_ref'] = gp[0]
#        new_h_attrs['group_comp'] = gp[1]
#      end
      
      puts p.to_json
      p.each_key do |k|
        
#        ### write in files some parameters that take too much space and replace in db by a SHA2                                                                                                    
#        if filename = @h_attrs[k]['write_in_file']
#          filepath = output_dir + filename
#          File.open(filepath, 'w') do |f|
#            f.write(params[:attrs][k])
#          end
#          sha2 = Digest::SHA2.hexdigest params[:attrs][k]
#          new_h_attrs = JSON.parse(run.attrs_json)
#          new_h_attrs[k] = sha2
#        end
        
        ### apply write_in_file               
        #        @h_attrs.each_key do |k|
        #     if filename = h_p[:h_attrs][k.to_s]['write_in_file']
        #       filepath = h_var['output_dir'] + filename
        #       File.open(filepath, 'w') do |f|
        #         f.write(h_p[:h_attrs][k.to_s])
        #       end
        #     end
        
        #logger.debug("bly: #{k.to_s} #{@h_attrs.to_json} #{@h_attrs[k.to_s].to_json}")                                                                                                            
        if h_p[:h_attrs][k.to_s] and h_p[:h_attrs][k.to_s]['valid_types']
          
          ### handle annotations (that are not considered as datasets - but can still be used as input)

          ### handle datasets
          
          if h_p[:h_attrs][k.to_s]['valid_types'].flatten.include?('dataset')
          
            list_datasets = []            
            if h_p[:h_attrs][k.to_s]['req_data_structure'] == 'array' and !h_p[:h_attrs][k.to_s]['combinatorial_runs'] and p[k] and !p[k].empty?
              ### cases where there are several items
              logger.debug(p[k].to_json)
              list_datasets = p[k]
              #              h_var[k]=[]
            else
              list_datasets = [p[k]]
            end
            
            tmp_var = [] 

            list_datasets.each do |dt|
              linked_run = Run.where(:id => dt['run_id']).first
              h_parent_runs[linked_run.id] = linked_run
              h_linked_run_outputs = nil
              if !linked_run
                h_res[:error] = 'Linked run was not found!'
              else
                h_linked_run_outputs = JSON.parse(linked_run.output_json)
                output_key = ['output_filename', 'output_dataset'].map{|e| dt[e]}.compact.join(":")
                h_linked_run_output = h_linked_run_outputs[dt['output_attr_name']][output_key]
                if list_datasets.size == 1
                  if h_linked_run_output
                    h_linked_run_output.each_key do |k2|
                      h_var[k + "_" + k2] = h_linked_run_output[k2]
                    end
                     h_var[k + "_is_count_table"] = (h_linked_run_output["types"].flatten.include?("int_matrix")) ? 'true' : 'false'
                  end
                  h_var[k + "_filename"] = project_dir + dt['output_filename']
                  h_var[k + "_run_id"] = dt['run_id']
                  logger.debug ">>>>#{k}_run_id => #{dt['run_id']}"
                 
 #                 h_var[k + "_is_count_table"] = (h_linked_run_output["types"].flatten.include?("int_matrix")) ? 'true' : 'false' 
                else
                  ## if we consider linking datasets from other files
                  #                  h_var[k].push((project_dir + dt['output_filename']) + ":" + dt['output_attr_name'])
                  ## instead lets only consider the datasets from the current file and  restrict the available datasets to the file direct lineage + descendents
                  tmp_var.push(dt['output_attr_name'])
                end

                h_parent = {
                  :run_id => linked_run.id,
                     :lineage_run_ids => linked_run.lineage_run_ids,
                  :type => 'dataset',
                  :output_attr_name => dt['output_attr_name'],
                  #   :filename => dt['output_filename'], 
                  #   :dataset => dt['output_dataset'], #h_linked_run_output['dataset'],
                  :output_json_filename => (oj = h_linked_run_outputs['output_json']) ? oj.keys.first : nil,    
                  :input_attr_name => k.to_s
                }

                #                [:dataset].each do |e|
                #                  h_parent[e] =  h_linked_run_output[e.to_s]
                #                end
                
                run_parents.push(h_parent)
              end
            end
            if list_datasets.size > 1
              h_var[k] = tmp_var.join(",")
            else
              h_var[k] = tmp_var[0]
            end
          end
        else
          h_var[k] = p[k]
        end
      end

      logger.debug("H_VAR: " + h_var.to_json)

      ### update parents's children
      run_parents.each do |run_parent|
        parent_run = h_parent_runs[run_parent[:run_id]]
        children_run_ids = parent_run.children_run_ids.split(",")
        children_run_ids.push(run.id)
        #        parent_run.update_attribute(:children_run_ids, children_run_ids.join(","))
        h_upd = {:children_run_ids => children_run_ids.join(",")}
        upd_run h_p[:project], parent_run, h_upd
      end
      
      ## get all runs being in the lineages ## it is already done above one by one...
      #      h_all_runs = {}
      #      Run.where(:id => all_run_ids).all.each do |run|
      #       h_all_runs[run.id]=run
      #      end
      
      ## define if predictable = there is one matrix as input                                                                                                                                      
      matrix_runs = run_parents.select{|parent| parent[:type] == 'dataset'}
      predictable = (matrix_runs.size == 1) ? true : false
      if predictable
        matrix_run = matrix_runs.first
        h_output_json = JSON.parse(File.read(project_dir + matrix_run[:output_json_filename]))
        h_var['nber_cols'] = h_output_json['nber_cols']
        h_var['nber_rows'] = h_output_json['nber_rows']
      end
      
      list_args = []
      if h_p[:h_cmd_params]['args']
          h_p[:h_cmd_params]['args'].each do |h_arg|
          logger.debug "H_ARG: " + h_arg.to_json
          std_method_attr = h_std_method_attrs[h_arg['param_key']]          
          value = (h_arg['value'] || h_var[h_arg['param_key']] || ((std_method_attr) && std_method_attr['default'])).dup
          logger.debug "VALUE: " + value.to_json
          value.to_s.gsub!(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] }
          list_args.push({:param_key => h_arg['param_key'], :value => (value != nil and value != '') ? value : h_arg["null_value"]})
        end
      end
      
      list_opts = []
      if h_p[:h_cmd_params]['opts']
        h_p[:h_cmd_params]['opts'].each do |opt|
          std_method_attr = h_std_method_attrs[opt['param_key']]
          value = (opt['value'] || h_var[opt['param_key']] || (std_method_attr && std_method_attr['default'])).dup
          logger.debug "VALUE: #{opt}: " + value.to_json          
          value.to_s.gsub!(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] }
          list_opts.push({:opt => opt['opt'], :param_key => opt['param_key'], :value => (value != nil and value != '') ? value : opt["null_value"]})
        end
      end
      
      host_name =  h_p[:h_cmd_params]['host_name'] || 'localhost'
      container_name = APP_CONFIG[:asap_instance_name] + "_" + run.id.to_s

#      logger.debug "ATTRS_json: " + h_p[:h_attrs].to_json
#      logger.debug "H_VAR: " + h_var.to_json

      h_env_docker_image = h_p[:h_env]['docker_images'][docker_image]
      image_name = h_env_docker_image['name'] + ":" + h_env_docker_image['tag']
      h_cmd = {
        :host_name => host_name,
        :container_name => container_name,
        :docker_call => (docker_image) ? h_env_docker_image['call'].gsub(/\#image_name/, image_name) : nil,
        :time_call => h_p[:h_env]['time_call'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },
        :exec_stdout =>  h_p[:h_env]['exec_stdout'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },
        :exec_stderr =>  h_p[:h_env]['exec_stderr'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },
        :program =>  h_p[:h_cmd_params]['program'],
        :args => list_args,
        :opts => list_opts
      }
        
      if predictable
        
        h_predict_params = {}
        h_p[:h_cmd_params]['predict_params'].each do |pp|
          h_predict_params[pp] = h_var[pp]
        end
        
        h_cmd[:expected_duration] = Basic.predict_duration(h_predict_params)
        h_cmd[:expected_ram] = Basic.predict_ram(h_predict_params)
      end

      logger.debug "CMD_JSON" + h_cmd.to_json

      run_parents_to_save = []
      run_parents.each do |e|
        h_parent = {}
        [:run_id, :type, :output_attr_name, :input_attr_name].each do |k2|
          h_parent[k2] = e[k2]
        end
        run_parents_to_save.push(h_parent)
      end
      
      h_upd = {
        :attrs_json => new_h_attrs.to_json,
        :command_json => h_cmd.to_json,
        :run_parents_json => run_parents_to_save.to_json,        
        :lineage_run_ids => (run_parents and run_parents.size > 0) ? (run_parents.map{|e| e[:lineage_run_ids].split(",").map{|e| e.to_i}}.flatten + run_parents.map{|e| e[:run_id]}).uniq.sort.join(",") : ""
      }

      upd_run h_p[:project], run, h_upd
      #  run.update_attributes({
      #                          #                              :host_name => host_name,
      #                          #                              :container_name => container_name, 
      #                          :command_json => h_cmd.to_json, 
      #                          :run_parents_json => run_parents.to_json
      #                        });
      
      return h_res
      
    end

#    def init_active_run run    
#      h_res = {}
#      h_active_run = run.as_json
#      h_active_run[:run_id] = run.id
#      ar = ActiveRun.new(h_active_run)
#      ar.save!
#      return h_res
#    end

    def predict_ram h_predict_param
      return nil
    end

    def predict_duration h_predict_param
      return nil
    end
    
    def build_docker_cmd h_cmd, core_cmd
      cmd = core_cmd
      if h_cmd['docker_call']
        puts ">#{h_cmd['container_name']}-#{h_cmd['docker_call']}"
        h_cmd['docker_call'].gsub!(/\#container_name/, h_cmd['container_name'])
        host_option = ""
        if h_cmd['host_name'] != 'localhost'
          host_option = "-H #{h_cmd['host_name']}"
        end
        h_cmd['docker_call'].gsub!(/\#host_option/, host_option)

        cmd = h_cmd['docker_call'] + " \"" + core_cmd + "\""
      end
      return cmd
    end


    def build_cmd h_cmd
      puts "H_CMD: " + h_cmd.to_json
       h_cmd['opts']||=[]
       h_cmd['args']||=[]
      puts "H_CMD: " + h_cmd.to_json
      
      cmd_parts = [
                   h_cmd['program'],
                   h_cmd['opts'].map{|e| "#{e['opt']} #{e['value']}"}.join(" "), 
                   h_cmd['args'].map{|e| e['value']}.join(" "),
                   (h_cmd['exec_stdout']) ? "1> #{h_cmd['exec_stdout']}" : nil,
                   (h_cmd['exec_stderr']) ? "2> #{h_cmd['exec_stderr']}" : nil
                  ]
      cmd = "sh -c '" + cmd_parts.compact.join(" ") + "'" 
      
      cmd_core = [h_cmd['time_call'], cmd].compact.join(" ") 
      #  h_cmd['program'], 
      #              h_cmd['opts'].map{|e| "#{e['opt']} #{e['value']}"}.join(" "), h_cmd['args'].map{|e| e['value']}].compact.join(" ")
      puts "CMD_CORE: " + cmd_core
      cmd = build_docker_cmd(h_cmd, cmd_core)
      #      if h_env['docker_call']
      #        cmd = h_env['docker_call'] + "\"" + cmd_core + "\""
      #      end
      return cmd
    end

    def file_matches? output_dir, k, h_expected_outputs, filename, filepath
      exp_filename = h_expected_outputs[k]['filename'] if h_expected_outputs[k]['filename']
      exp_filename_regexp = output_dir + h_expected_outputs[k]['filename_regexp'] if h_expected_outputs[k]['filename_regexp']
      exp_filepath_regexp = output_dir + h_expected_outputs[k]['exp_filepath_regexp'] if h_expected_outputs[k]['exp_filepath_regexp']
      puts "CHECK: #{k}, #{filename}, #{exp_filename}"
      return (exp_filename and filename and  filename == exp_filename)
      #(exp_filename or exp_filename_regexp or exp_filepath_regexp) and (!exp_filename or filename == exp_filename)
      #  and (!exp_filename_regexp or filename.match(/#{exp_filename_regexp}/)) and 
      # (!exp_filepath_regexp or filepath.match(/#{exp_filepath_regexp}/))
      #       )
    end

    def update_h_output_files h, annot
      ### update dataset_size, nber_cols, nber_row from added annots
      h['nber_cols'] = annot.nber_cols
      h['nber_rows'] = annot.nber_rows
      h['dataset_size'] = annot.mem_size
      return h
    end

    def exec_run_sync_stdout logger, run
      
      start_time = Time.now
      
      project = run.project
      version = project.version
      step = run.step
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first

      h_data_types = {}
      DataType.all.map{|dt| h_data_types[dt.name] = dt}

      h_upd = {
        :status_id => 2,
        :start_time => start_time,
        :waiting_duration => start_time - run.created_at #submitted_at                                                                                                               
      }
      upd_run project, run, h_upd
      project.broadcast step.id

      ## define output_dir                                                                                                                                                          

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
      step_dir = project_dir + step.name
      Dir.mkdir step_dir if !File.exist? step_dir
      output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir

      Dir.mkdir output_dir if !File.exist? output_dir
      
      h_cmd = JSON.parse(run.command_json)
      
      cmd = build_cmd(h_cmd)
      logger.debug("CMD:#{cmd}")
      puts "CMD: " + cmd
    #  pid = spawn(cmd)
      h_results = `#{cmd}`
      finish_run logger, run, h_results
      
      return h_results
      
    end

    def exec_run logger, run

      start_time = Time.now
      
      project = run.project
      version = project.version
      step = run.step
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first

      h_data_types = {}
      DataType.all.map{|dt| h_data_types[dt.name] = dt}

      h_upd = {
        :status_id => 2,
        :start_time => start_time,
        :waiting_duration => start_time - run.created_at #submitted_at
      }
      upd_run project, run, h_upd
      project.broadcast step.id

      ## define output_dir                                                                                                                                                                   
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
      step_dir = project_dir + step.name
      Dir.mkdir step_dir if !File.exist? step_dir
      output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir

      Dir.mkdir output_dir if !File.exist? output_dir

      ## initialize directoy: remove files but keep directories (directory ./input contains things added previously from an interaction with the browser) 
      Dir.new(output_dir).entries.select{|f| File.directory?(f) == false}.each do |f|
        #  File.delete output_dir + f  ### do not delete finally because we cannot run again a given run   
      end
      
      h_attrs = JSON.parse(run.attrs_json)
      
      res = ''

      ## execute command                                                                                                                                                                     

      hca_output_json_file = project_dir + 'parsing' + "get_loom_from_hca.json"
      h_output_hca = JSON.parse(File.read(hca_output_json_file)) if File.exist? hca_output_json_file

       all_displayed_errors = []

      if !h_output_hca or h_output_hca['status_id'] !=4

        h_cmd = Basic.safe_parse_json(run.command_json, {})
        if h_cmd.keys.size == 0
          all_displayed_errors.push("Not valid command")
        else
          cmd = build_cmd(h_cmd)
          logger.debug("CMD:#{cmd}")
          if run.return_stdout == true
            res = `#{cmd}`
          else
            puts "CMD: " + cmd
            pid = spawn(cmd)
            Process.waitpid(pid)
          end
        end
      else
        all_displayed_errors.push("Error from HCA: " + h_output_hca['error'])
      end

      output_json_filename = output_dir + 'output.json'
      h_results = {}
      if run.return_stdout == true
        h_results = Basic.safe_parse_json(res, {})
      elsif File.exist? output_json_filename
        h_results = Basic.safe_parse_json(File.read(output_json_filename), {})
      end
      
      if ! ($? and ! $?.stopped?) or h_results.keys.size == 0
        status_id = 4
        h_results['displayed_error'] = all_displayed_errors if all_displayed_errors.size > 0
        h_results['displayed_error']||=[]       
        h_results['displayed_error'].push('Stopped')        
      #        commit_finished_run logger, run, h_results, h_output_files
      end

      #### patch
      if step.id == 16
        h_results = {"metadata" => [h_results]}
      end

      h_results = finish_run logger, run, h_results

      return (run.return_stdout == true) ? res : nil

    end
    
    def finish_run logger, run, h_results
      
      #      start_time = Time.now
      
      project = run.project
      version = project.version
      step = run.step
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first
      
      h_data_types = {}
      DataType.all.map{|dt| h_data_types[dt.name] = dt}

      start_time = run.start_time
  
#      h_upd = {
#        :status_id => 2, 
#        :start_time => start_time, 
#        :waiting_duration => start_time - run.submitted_at
#      }
#      upd_run project, run, h_upd
#      project.broadcast step.id
     
      ## define output_dir
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key 
      step_dir = project_dir + step.name
      Dir.mkdir step_dir if !File.exist? step_dir
      output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      
      Dir.mkdir output_dir if !File.exist? output_dir
      
      ## initialize directoy: remove files but keep directories (directory ./input contains things added previously from an interaction with the browser)
      Dir.new(output_dir).entries.select{|f| File.directory?(f) == false}.each do |f|
      #  File.delete output_dir + f  ### do not delete finally because we cannot run again a given run
      end

      h_attrs = JSON.parse(run.attrs_json)
      
      ## execute command

      h_var = { 
        'user_id' => project.user_id,
        'project_dir' => project_dir,
        'output_dir' => output_dir, #project_dir + step.name + run.id.to_s,
        'step_tag' => step.tag,
        'std_method_name' => (std_method = run.std_method) ? std_method.name : step.name,
        'run_num' => run.num
      }

      hca_output_json_file = project_dir + 'parsing' + "get_loom_from_hca.json"
      h_output_hca = JSON.parse(File.read(hca_output_json_file)) if File.exist? hca_output_json_file
      all_displayed_errors = []
      if h_results['displayed_error'].is_a?(Array)
        all_displayed_errors = h_results['displayed_error']
      elsif h_results['displayed_error'].is_a?(String)
        all_displayed_errors.push h_results['displayed_error']
      end
      #      if !h_output_hca or h_output_hca['status_id'] !=4
      
      h_env = Basic.safe_parse_json(version.env_json, {})
      puts run.to_json
      h_cmd = Basic.safe_parse_json(run.command_json, {})     
      #      puts h_cmd.to_json
      
      ## add cmd arguments in h_var to get the output_matrix_filename
      if h_cmd['args']
        #       puts "ARGS: " + h_cmd["args"].to_json
        h_cmd['args'].each do |a|
          h_var[a["param_key"]] = a["value"]
        end
      end
      if h_cmd['opts']
        h_cmd['opts'].each do |a|
          h_var[a["param_key"]] = a["value"]
        end
      end
      
      #      ## check if expected output files exist                                                                                                                         
      #      h_output_json_db = JSON.parse(step.output_json)
      #      h_expected_outputs = (h_output_json_db) ? h_output_json_db['expected_outputs'] : nil
      
      ## compute size of files before run execution
      #      if h_expected_outputs
      #        h_file_size_before_exec = {}
      #        h_expected_outputs.each_key do |k|
      #          puts           h_expected_outputs[k].to_json
      #          if h_expected_outputs[k]["filepath"]          
      #            dataset_path = (h_expected_outputs[k]['dataset']) ? h_expected_outputs[k]['dataset'].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] } : nil
      #            filepath = h_expected_outputs[k]["filepath"].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] }
      #            if h_expected_outputs[k]["filepath"]
      #              h_file_size_before_exec[filepath] = File.size(filepath)
      #            end
      #          end
      #        end
      #      end
      
      #        cmd = build_cmd(h_cmd)
      #        logger.debug("CMD:#{cmd}")
      #        puts "CMD: " + cmd 
      #        pid = spawn(cmd)
      
      #  h_pids = {
      #    :in_docker => nil,
      #    :cmd => nil
      #  }
      #  if h_env['docker_call']
      #    h_pids[:cmd] = tmp_pid
      #    in_docker_pid_file = output_dir + 'cmd.pid'
      #    h_pids[:in_docker] = File.read( cmd_pid_file) if File.exist? in_docker_pid_file
      #  else
      #    h_pids[:cmd] = tmp_pid
      #  end
      
      #        h_run = {
      #          #    :command_line => cmd,
      #          :status_id => 2,
      #          #    :in_docker_pid => h_pids[:in_docker],
      #          #    :cmd_pid => h_pids[:cmd]
      #          #    :pid = pid        
      #        }
      #        upd_run project, run, h_run
      #        #      run.update_attributes(h_run)
      #        project.broadcast run.step_id
      #        
      #        Process.waitpid(pid)
      #        
      #      else
      #        all_displayed_errors.push("Error from HCA: " + h_output_hca['error'])
      #      end
      
      #     logger.debug "CMD_STATUS: #{$?.stopped?}"
      
     # output_json_filename = output_dir + 'output.json'
      # h_results = {}
      
      #      if $? and ! $?.stopped?  #(job and ! $?.stopped?) or (results["original_error"] or results["displayed_error"])             
      
      ## check if expected output files exist                            
      h_output_json_db = Basic.safe_parse_json(step.output_json, {})
      h_expected_outputs = (h_output_json_db) ? h_output_json_db['expected_outputs'] : nil
      
      
      ## get list of files produced
      output_files = Dir.new(output_dir).entries.select{|e| !e.match(/^\./)}
      h_output_files = {}
      
      #        puts "output_files: #{output_files.to_json}"
      
      ## attribute files to expected output keys
      
      #        ## check if expected output files exist
      #        h_output_json_db = JSON.parse(step.output_json)        
      #        h_expected_outputs = (h_output_json_db) ? h_output_json_db['expected_outputs'] : nil
   
#      puts "H_OUTPUT_DB #{step.id} #{h_output_json_db.to_json}"
      puts "H_EXPECTED_OUTPUTS. #{h_expected_outputs.to_json}"
   
      onum = 1
      if h_expected_outputs
        h_expected_outputs.each_key do |k|
          
          dataset_path = (h_expected_outputs[k]['dataset']) ? h_expected_outputs[k]['dataset'].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] } : nil
          
          #         puts "k: "+ k 
          ### check if the file is at the path if the expected path is not including the standard output directory                      
          
          if h_expected_outputs[k]["filepath"]
            #           puts "BLA22: " + h_expected_outputs[k]["filepath"]
          #  puts h_var.to_json
            #  dataset_path = (h_expected_outputs[k]['dataset']) ? h_expected_outputs[k]['dataset'].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] } : nil
            filepath = h_expected_outputs[k]["filepath"].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] }
       #     puts "COMPUTE_RELATIVE_PATH: #{project.id}, #{filepath}" 
            relative_filepath = relative_path(project, filepath)
            output_key = [relative_filepath, dataset_path].compact.join(":")
       #     puts "OUTPUT_KEY: #{output_key}"
            #            puts "FILEPATH22: " + filepath
            if File.exists? filepath
              h_output_files[k]||={}
              h_output_files[k][output_key]={ "onum" => onum, "filename" => File.basename(filepath), "dataset" => dataset_path, "types" => h_expected_outputs[k]["types"]}
              #  ["dataset"].select{|k2| h_expected_outputs[k][k2]}.each do |k2|
              #    h_output_files[k][filepath][k2] = h_expected_outputs[k][k2].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] }
              #  end
            #              puts "H_OUTPUT_FILE22: " + h_output_files[k].to_json
              onum+=1
            end
          else
            ### check output files present in the standard output directory
            output_files.each do |filename|
              filepath = relative_path(project, output_dir + filename)  #[step.name, run.id, filename].join("/")
              #    dataset_path = (h_expected_outputs[k]['dataset']) ? h_expected_outputs[k]['dataset'].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] } : nil
              output_key = [filepath, dataset_path].compact.join(":")
         #     puts "OUTPUT_KEY2: #{output_key}"
              if file_matches?(output_dir, k, h_expected_outputs, filename, filepath)   
                h_output_files[k]||={}
                h_output_files[k][output_key] ||= {"onum" => onum, "filename" => filename, "dataset" => dataset_path, "types" =>  h_expected_outputs[k]["types"]}            
                #   ["dataset"].select{|k2| h_expected_outputs[k][k2]}.each do |k2|
                #     h_output_files[k][filepath][k2] = h_expected_outputs[k][k2].gsub(/(\#\{[\w_]+?\})/) { |var| h_var[var[2..-2]] } 
                #   end
                
                onum+=1
                break
              end
            end
          end
          if !h_output_files[k]
            ### no files in the output directory
            if !h_expected_outputs[k]["optional"] or h_expected_outputs[k]["optional"] == false
              rendered_filename = (h_expected_outputs[k]["filename"]) ? h_expected_outputs[k]["filename"] : k
              all_displayed_errors.push((rendered_filename == 'output.json') ? "Something went wrong." : "#{rendered_filename} file is missing.") 
              # all_displayed_errors.push( "#{rendered_filename} file is missing.")
            end
          end
        end
      end
      ## add output files not expected but indicated in the JSON as existing_metadata
      
      
      ### get unexpected files
      #output_files.each do |filename|
        #  filepath = output_dir + filename
      #  flag = 0
      #   h_output_files.each_key do |k|
      #    h_output_files[k].each_key do |f|
      #      flag== 1 if filepath == f
      #    end
      #  end
      #end
        
      #      puts "H_OUTPUT_FILES: #{h_output_files.to_json}" 
      #      puts "H_EXP_OUTPUT_FILES: #{h_expected_outputs.to_json}"
      #        results = {}
      
      #found_expected = true
      #h_expected_outputs.each_key do |k|
      #  filename = output_dir + h_expected_outputs[k]['filename']
      #  if !h_expected_outputs[k]['optional']
      #    found_expected = false if !File.exist? filename
      #          end
      #        end
      
      
      ### check if json results is parseable, if not write an error to be complemented
      #if File.exist? output_json_filename
      #  begin
      #    h_results = JSON.parse(File.read(output_json_filename))          
      #    all_displayed_errors.push(h_results['displayed_error']) if h_results['displayed_error']
      #  rescue Exception => e
      #    #         puts "BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD"
      #    all_displayed_errors.push('Bad JSON format of results file output.json' + e.message)
      #  end
      #  #      puts "DISPLAYED_ERROR: " + all_displayed_errors.to_json
      #end
      #    puts "DISPLAYED_ERROR2: " + all_displayed_errors.to_json
      
      h_json_data = {}
      
      #        if all_displayed_errors.size == 0
      
      ### TRY TO DO WITHOUT DESCRIBING OUTPUTS IN THE JSON FILE
      ### get results
      #          if h_results['outputs']
      #            h_results['outputs'].each_key do |k|
      #              h_results['outputs'][k].each_key do |filepath|
      #                filename = filepath.split("/").last
      #                errors = []
      #                prop = h_results['outputs'][k][filepath]
      #                
      #               ## update types to the ones described in results                          
      #               h_output_files[k][f]["types"] = prop["types"] if prop["types"]
      #                
      #                ## k exists but file doesnt't match
      #                if h_output_files[k] 
      #                  if file_matches?(output_dir, k, h_expected_outputs, filename, filepath) == false
      #                    errors.push("#{f}: File doesn't match with filename description")
      #                  elsif !h_output_files[k][filepath] ## file matches constrains but not found in the output_dir directory => complete h_output_files
      #                    h_output_files[k][filepath] = prop
      #                  end
      #                end
      #                
      #                ## file not found in output directory
      #                if !h_output_files[k][filepath] and h_expected_outputs[k]["mandatory"]
      #                  error_txt = "#{f}: " + (h_expected_outputs[k]["mandatory"] == true) ? "File not found." : h_expected_outputs[k]["mandatory"]
      #                  errors.push(error_txt)
      #                end
      #            
      #                ### write error if exists
      #                if errors.size > 0
      #                  h_output_files[k][filepath]["errors"] = errors 
      #                  all_displayed_errors += errors
      #                end
      #                
      #              end
      #            end
      #          end
      
      ### check all files        
      
      #  h_json_data = {}
      
      no_error = true if  all_displayed_errors.size == 0
      
      h_output_files.each_key do |k|
        h_output_files[k].each_key do |k2|
          t = k2.split(":")
          relative_path = t[0]
          #            dataset_path = t[1] if t.size > 1
          
          filepath = project_dir + relative_path
          #       puts "FILEPATH:  " + filepath.to_s
          errors = []            
          ## compute size                                                                                                                                                       
          h_output_files[k][k2]["size"] = File.size(filepath)
          #            h_output_files[k][k2]["dataset_size"] = h_output_files[k][k2]["size"] - h_file_size_before_exec[filepath] if h_file_size_before_exec[filepath]
          ## check JSON errors               
          json_data = nil            
          # puts "BLAAAA_TYPES: #{h_output_files[k][k2]["types"]}"
          if h_output_files[k][k2]["types"].include?("json_file")
            begin
              json_data = JSON.parse(File.read(filepath))
              h_json_data[k] ||= {}
              h_json_data[k][filepath] = json_data ## only one json per output key allowed 
            rescue Exception => e
              #   puts "VERY BAAAAAAAAAAAAAAAAAAD" + e.backtrace.to_json
              errors.push('Bad JSON format')
            end
          end
          
          ## check size                                       
          
          #  puts "Check size of #{k} : #{h_output_files[k][k2]['size']} #{json_data.to_json}!"
          
          if (h_output_files[k][k2]["size"] == 0 or (h_output_files[k][k2]["types"].include?("json_file") and json_data and json_data.is_a? Hash and json_data.keys.size == 0)) and h_expected_outputs[k]["never_empty"]
            puts "Add error for #{k}!"
            error_txt = "#{h_output_files[k][k2]['filename']}: File is empty."
            errors.push(error_txt)
          end
          
          ### write error if exists       
          if errors.size > 0 and no_error == true
            h_output_files[k][k2]["errors"] ||=[]
            h_output_files[k][k2]["errors"] += errors
            all_displayed_errors += errors
          end
        end
      end
      
      ### replace outputs with h_output_files => to simplify debugging, finally just save in database
      #h_results['outputs'] = h_output_files
      
      #       end
      
#      h_output_json = (h_json_data['output_json'] and output_json_filename) ? h_json_data['output_json'][output_json_filename] : {}
      #  puts "H_OUTPUT_JSON: " + h_output_json.to_json
      
      ## get metadata by name
      h_metadata_by_name = {}
      if h_results['metadata']
        h_results['metadata'].each do |metadata|
          h_metadata_by_name[metadata['name']] = metadata
        end
      end

      loaded_annots = []
      
      ## edit type of output_files in function of properties described in output.json
      h_output_files.each_key do |k|
        h_output_files[k].each_key do |k2|           
      #    puts k + "-->" + k2
          t = k2.split(":")
      #    puts "RELATIVE_PATH: #{t[0]}"
          relative_filepath = t[0]
        #  relative_filepath = relative_path(project, filepath)
          fo = create_upd_fo project.id, relative_filepath
      #    puts "rel_path: " + relative_filepath.to_json
      #    puts "types: " + h_output_files[k][k2]["types"].to_json
          if h_output_files[k][k2]["types"].include?("dataset")
            #                h_output_files[k][k2]["types"].push((h_output_json and h_output_json['is_count_table'].to_i == 1) ? "int_matrix" : "num_matrix")               
            #   t = k2.split(":")
            #   relative_filepath = t[0]
            #   fo = create_upd_fo project.id, relative_filepath
            # h_output_files[k][k2]["fo_id"] = fo.id
            filepath = project_dir + t[0]
            # if h_output_json['metadata']
            dataset_name = h_output_files[k][k2]["dataset"]
          #   puts "DATASET name: #{dataset_name.to_json}"
            if dataset_name
         #     puts "DATASET name: #{dataset_name}"
              if dataset_name == '/matrix' or dataset_name.match(/^\/layers\//)
                h_output_files[k][k2]["types"].push((h_results and h_results['is_count_table'].to_i == 1) ? "int_matrix" : "num_matrix")
                h_output_files[k][k2]["nber_rows"] = h_results['nber_rows']
                h_output_files[k][k2]["nber_cols"] = h_results['nber_cols']
                h_output_files[k][k2]["dataset_size"] = (h_results['nber_rows'] and h_results['nber_cols']) ? 4 * h_results['nber_rows'] * h_results['nber_cols'] : nil
                
                h_data = {
                  'nber_cols' => h_results['nber_cols'],
                  'nber_rows' =>  h_results['nber_rows'],
                  'type' => 'NUMERIC',
                  'on' => 'EXPRESSION_MATRIX',
                  'dataset_size' => h_output_files[k][k2]["dataset_size"],                    
                  'name' => dataset_name,
                  'count' => (h_results and h_results['is_count_table'].to_i == 1) ? true : false
                }
            #    puts "H_DATA: #{h_data.to_json}"
                new_annot = load_annot(run, h_data, relative_filepath, h_data_types)
                h_output_files[k][k2] = update_h_output_files(h_output_files[k][k2], new_annot)
                #  puts  h_output_json.to_json
                
                if  h_metadata_by_name.keys.size > 0
                  h_metadata_by_name.each_key do |meta_name|
                    metadata = h_metadata_by_name[meta_name]
                    new_annot = load_annot(run, metadata, relative_filepath, h_data_types)
                    h_output_files[k][k2] = update_h_output_files(h_output_files[k][k2], new_annot)
                  end
                end
              elsif h_results['metadata'] and metadata = h_metadata_by_name[dataset_name]
                # puts metadata.to_json
                h_output_files[k][k2]["nber_rows"] = metadata['nber_rows']
                h_output_files[k][k2]["nber_cols"] = metadata['nber_cols']
                h_output_files[k][k2]["dataset_size"] = metadata['dataset_size'] #() ? 4 * metadata['nber_rows'] * metadata['nber_cols']
             #   puts "load annot!"
                new_annot = load_annot(run, metadata, relative_filepath, h_data_types)
                h_output_files[k][k2] = update_h_output_files(h_output_files[k][k2], new_annot)
                if metadata['type']
                  h_output_files[k][k2]["types"].push("#{metadata['type'].downcase}_annot")
                end
                #                if metadata['type'] == 'DISCRETE'
                #                  h_output_files[k][k2]["types"].push("categorical_annot") 
                #                elsif ['NUMERIC', 'STRING'].include? metadata['type']
                #                  h_output_files[k][k2]["types"].push("continuous_annot")
                #                end
                #  end
              end
            end
          end
          if h_results['output_files'] and h_results['output_files'][k2] and h_results['output_files'][k2]["types"]
            h_output_files[k][k2]["types"] |= h_results['output_files'][k2]["types"]
          end
        end
      end
      

#      ### update dataset_size, nber_cols, nber_row from added annots
#      h_annots={}
#      loaded_annots.each do |annot|
#        output_key = "#{annot.filepath}:#{annot.name}"
#        h_annots[][output_key]
#      end

      h_results['displayed_error'] = all_displayed_errors.uniq if all_displayed_errors.size > 0
      
    #  commit_finished_run logger, run, h_results, h_output_files
      
      #h_outputs = {}
      ### fill h_outputs
      #        h_expected_outputs.each_key do |k|
      #          filename = output_dir + h_expected_outputs[k]['filename']
      #### dans le fichier output.json il faut decrire les fichiers qui sont produits - filename avec le chemin relatif dans le projet 
      #### !!!!!! NOT FINISHED => must be written in the output.json and used also in the block above
      #          if File.exist? filename
      #            h_outputs[k] = {:filename => filename, :type => results['outputs'][k]['type']})
      #          end
      #        end
      
      ### update duration    
      #      else
      #        status_id = 4
      #        h_results['displayed_error'] = all_displayed_errors if all_displayed_errors.size > 0
      #        h_results['displayed_error'].push('Stopped')
      #      end
      
#    end

#    def commit_finished_run logger, run, h_results, h_output_files

 #     start_time = run.start_time
 #     project = run.project
 #     version = project.version
 #     step = run.step
 #     project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first

 #     ## define output_dir        
 #     project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
 #     step_dir = project_dir + step.name
 #     Dir.mkdir step_dir if !File.exist? step_dir
 #     output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
   
      ### get time info                                                                                                                                                                      
      h_time_info = {}
      time_info_filename = output_dir + 'exec_run_details.log'
      if File.exist? time_info_filename
        File.readlines(time_info_filename).each do |l|
          t = l.split(",")
          if t.size > 1
            t.each do |e|
              logger.debug(e)
              if m = e.match(/^([A-Za-z])=([\d\:.]+)$/)
                h_time_info[m[1]] = m[2]
              end
            end
          end
        end

        process_duration = 0.0
        if h_time_info['E']
          t = h_time_info['E'].split(":")
          if t.size == 3
            process_duration += t.shift.to_f * 3600
          end
          if t.size == 2
            process_duration += t[0].to_f * 60
            process_duration += t[1].to_f
          end
          logger.debug("TIME_INFO: " + h_time_info.to_json)
        end
      end

      duration = (start_time) ? (Time.now - start_time) : nil 

      #  puts "OUTPUT_JSON = " +  h_output_files.to_json                                                                                                                                             
      status_id = (!h_results["original_error"] and !h_results["displayed_error"]) ? 3 : 4

      ### check if it might be a problem of memory
      #puts "BLA"
      if status_id == 4
        d = `free top`
      #  puts "FREE TOP: " + d
        free_mem = d.split(/\n/)[1].split(/\s+/)[3]
      #  puts "FREE MEM: " + free_mem
        if free_mem 
          diff =  free_mem.to_i - h_time_info['M'].to_i
          if diff < 10000000
            h_results["displayed_error"] = ['Probably out of RAM.']
          end
       #   puts "MEM: #{free_mem.to_i} - #{h_time_info['M'].to_i} = " + (diff).to_s
        end
      end

      ### write final results                    
      if run.return_stdout == false
        output_json_filename = output_dir + 'output.json'
        if File.exists? output_json_filename and h_results['displayed_error'] and h_results['displayed_error'].include?('Bad JSON format')
          FileUtils.cp output_json_filename, (output_dir + 'output.json.bad')
        end
        File.open(output_json_filename, 'w') do |f|
          f.write(h_results.to_json)
        end
      end

      h_upd = {
        :output_json => h_output_files.to_json,
        :status_id => status_id,
        :duration => duration,
        :waiting_duration => (start_time) ? (start_time - run.created_at) : nil,
        :process_duration => process_duration, #h_time_info['E'].split(":"),
        :process_idle_duration => h_results['time_idle'],
        :max_ram => h_time_info['M']
      }
      
      #      run && run.update_attributes(h_upd)
      #      h_project_step =  Basic.get_project_step_details(project, step.id)
      #      project_step.update_attributes(h_project_step)                                                                                                              
      run && upd_run(project, run, h_upd)
      upd_project_size project
   #   puts project.to_json
      #puts broadcast
      project.broadcast run.step_id
  #    puts "broadcast done"
      return h_results
    end
    
    def std_run(run)
      h = {:project_id => project.id, :step_id => step_id,  :status_id => 1, :speed_id => speed_id}
      job = Job.new(h)
      job.save
      o.update_attributes({job_id_key => job.id, :status_id => 1})
      return job
    end

    def create_job(o, step_id, project, job_id_key, speed_id = 1)
      h = {:project_id => project.id, :step_id => step_id,  :status_id => 1, :speed_id => speed_id}
      job = Job.new(h)
      job.save
      o.update_attributes({job_id_key => job.id, :status_id => 1})
      return job
    end
    
    def finish_step(logger, start_time, project, step_id, o, output_file, output_json)
      
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step_id).first

      #      logger.debug("BLA")

      ### check if there is not a step < 4 that is also < current project step that was updated after the last update of this step.
      
      #project_steps = ProjectStep.where("project_id = #{project.id} and step_id < 4 and step_id < #{step_id}")
      #alert = 0
      #project_steps.each do |ps|
      #  if ps.updated_at > project_step.updated_at
      #    alert = 1
      #    break
      #  end
      #end
      
      #if alert == 0
      
      results = {}
      if output_json and File.exists?(output_json)
        begin
          results = JSON.parse(File.read(output_json))
        rescue Exception => e
        end
      end

      logger.debug("JSON1: #{results.to_json}")

      duration = Time.now - start_time
      if File.exists?(output_file) and !results["original_error"] and !results["displayed_error"]
        logger.debug("SUCCESSFUL #{o.id}")
        o.update_attributes(:duration => duration, :status_id => 3)       
        if step_id != 4
          project.update_attributes(:duration => duration, :status_id => 3)
          project_step.update_attributes(:status_id => 3)
        end
      else
        logger.debug("FAILED #{o.id}")
        o.update_attributes(:duration => duration, :status_id => 4)
        if step_id != 4 and project_step.status_id != nil ## second part of condition to prevent to update project_step when a job is killed when an earlier step is restarted (necessary if the kill is slower than the update of the ps.status to nil)
          project.update_attributes(:duration => duration, :status_id => 4)
          project_step.update_attributes(:status_id => 4)
        end
      end
      
      project.broadcast step_id
      # end
    end
    
    def kill_job(logger, job)
      pid = (job) ? job.pid : nil
      if job 
        delayed_job = Delayed::Job.where(:id => job.delayed_job_id).first
        ### delete the job and delayed job if they are pending
        if job.status_id == 1
          delayed_job.destroy if delayed_job
          job.destroy        
        else
          if pid and `ps -ef | egrep '^rvmuser +#{pid} +' | wc -l`.to_i > 0
            
            ## kill main process                                                                                                                                                                                                                                                
            Process.kill('INT', pid) #Process::kill 0, job.pid                                                                                                                                                                                                              
            ## kill remaining children processes                                                                                                                                                                                                                                 
            processes = Sys::ProcTable.ps.select{ |pe| pe.ppid == pid }
            logger.debug("KILL CHILDREN: #{processes.map{|pe| pe.pid}}")
            processes.each do |pe|
              Process.kill('INT', pe.pid)
          end
            job.update_attributes(:status_id => 5)
            delayed_job.destroy if delayed_job
          end
        end
      end
    end

#    def kill_pid(docker_call, pid)
#      cmd_core = "kill -9 #{pid}"
#      cmd = build_docker_cmd(docker_call, docker_run_name, cmd_core)
#      `#{cmd}`
#    end
    
#    def get_children_pids(docker_call, pid)
#      cmd_core = "pgrep -P #{pid}"
#      cmd = build_docker_cmd(docker_call, docker_run_name, cmd_core)
#      return `#{cmd}`.split("\n")
#    end

    def is_running run
      h_cmd = JSON.parse(run.command_json)
      h_containers = list_containers(h_cmd['host_name'])
      is_running = false
      if h_containers[h_cmd['container_name']]
        is_running = true
      end
      return is_running
    end

    def list_containers(host_name)
      host_opt = (host_name == 'localhost') ? "" : "-H #{host_name}"
      cmd = "docker ps #{host_opt} --format '{{.Names}}\t{{.Image}}'"
      h_containers = {}
      list = `#{cmd}`.split("\n")
      list.each do |e|
        t = e.split("\t")
        h_containers[e[0]]= {:image => e[1]}
      end
      
      return h_containers
    end

    def kill_run(run)
      if run.command_json
        h_cmd = JSON.parse(run.command_json) 
#        host_opt = (h_cmd['host_name'] == 'localhost') ? "localhost" : "-H #{h_cmd['host_name']}"
        ## need to create private/public key when host is not localhost
        cmd = "ssh #{h_cmd['host_name']} 'docker kill #{h_cmd['container_name']}'"
        if h_cmd['host_name'] == 'localhost' and h_cmd['container_name'] and !h_cmd['container_name'].empty?
          cmd = "docker kill #{h_cmd['container_name']}"
        end
        puts cmd
        `#{cmd}`
      end
    end

    def kill_all_runs(project)
      project.runs.each do |run|
        kill_run(run)
      end
    end
    
#    def kill_run_old(logger, run, h_p)
#      
#      pid = (run) ? run.pid : nil
#      docker_image = h_p[:h_cmd_params]['docker_image']
#      docker_call = (docker_image) ? h_p[:h_env]['docker_images'][docker_image]['call'] : nil
#      ps_core_cmd = "ps -ef | egrep '^rvmuser +#{pid} +' | wc -l"
#      ps_cmd = build_docker_cmd(docker_call, docker_run_name, ps_core_cmd)
#
#      if run
#        #  delayed_job = Delayed::Job.where(:id => job.delayed_job_id).first                                                                                                                   #                                      
#        ### delete the job and delayed job if they are pending                                                                                                                                 #                                      
#        if run.status_id == 1
#          #    delayed_job.destroy if delayed_job                                                                                                                                              #                                      
#          run.destroy
#        else
#          if pid and `#{ps_cmd}`.to_i > 0
#            ## kill main process   
#            kill_pid(nil, pid)
#            run.update_attributes(:status_id => 5)
#          end
#        end
#      end
#
#    end


#    def kill_run_inside_docker(logger, run, h_p) ## if the pid corresponds to the job pid inside the docker
#      
#      pid = (run) ? run.pid : nil
#      docker_image = h_p[:h_cmd_params]['docker_image']
#      docker_call = (docker_image) ? h_p[:h_env]['docker_images'][docker_image]['call'] : nil
#      ps_core_cmd = "ps -ef | egrep '^rvmuser +#{pid} +' | wc -l"
#      ps_cmd = build_docker_cmd(docker_call, ps_core_cmd)
#
#      if run
#        #  delayed_job = Delayed::Job.where(:id => job.delayed_job_id).first
#        ### delete the job and delayed job if they are pending                                                                                                                                 #   
#        if run.status_id == 1
#          #    delayed_job.destroy if delayed_job
#          run.destroy
#        else
#          if pid and `#{ps_cmd}`.to_i > 0
#            ## kill main process          
#            #     Process.kill('INT', pid) #Process::kill 0, job.pid           
#            kill_pid(docker_call, pid)
#            ## kill remaining children processes                                                  
##            processes = Sys::ProcTable.ps.select{ |pe| pe.ppid == pid }
#            children_pids = get_children_pids(docker_call, pid)
#            logger.debug("KILL CHILDREN: #{children_pids.to_json}")
#            children_pids.each do |pe|
#              kill_pid(docker_call, pe)
#            end
#            run.update_attributes(:status_id => 5)
#         #   delayed_job.destroy if delayed_job
#          end
#        end
#      end
#
#    end
    
    def kill_jobs(logger, project_id, step_id, o =nil)
      jobs = []
#      if step_id < 5
      jobs = Job.where(:project_id => project_id, :step_id => step_id, :status_id => 2).all.to_a
      logger.debug("JOBS_TO_KILL: #{jobs.size}")
      if step_id == 4
        jobs = jobs.select{|j| j.command_line.match(/#{o.dim_reduction.name}/)}
      end
      logger.debug("JOBS_TO_KILL_2: " + jobs.size.to_s)
      
      jobs.each do |job| 
       kill_job(logger, job)
#        if job and `ps -ef | egrep '^rvmuser +#{job.pid} +' | wc -l`.to_i > 0
#          ## kill main process
#          Process.kill('INT', job.pid) #Process::kill 0, job.pid 
#          ## kill children processes
#          processes = Sys::ProcTable.ps.select{ |pe| pe.ppid == job.pid }#          logger.debug("KILL CHILDREN: #{processes}")
#          processes.each do |pe|
#            Process.kill('INT', pe.pid)
#          end
#          job.update_attributes(:status_id => 5)
#        end
      end
      #     end
    end

#     job = Basic.run_job(logger, cmd, self, self, 1, output_file, output_json, queue, self.parsing_job_id, self.user)

    def run_job(logger, cmd, project, o, step_id, output_file, output_json, queue, job_id, user)
      
      start_time = Time.now
      
      logger.debug("CMD2: " + cmd)

#      jobs = []
#      if step_id < 5
#        Basic.kill_jobs(logger, project.id, step_id, o)
#      end
      
      #      project_step = ProjectStep.where(:project_id => project.id, :step_id => step_id).first
      ### search potentially running script                                                                                                                    
      file = ''
      if m = cmd.match(/-f ([^ ]+)/)
        file = m[1]
      end
      logger.debug("CMD_ls : " + `ls -alt #{file}`)
      pid = spawn(cmd)
      logger.debug("CMD3: " + cmd)
      logger.debug("CMD_ls2 : " + `ls -alt #{file}`)
      job = Job.find(job_id)

      h_job = {
        :project_id => project.id,
        :step_id => step_id,
        :command_line => cmd,
        :status_id => 2,
        :user_id => (user) ? user.id : 1,
        :speed_id => queue,
        :pid => pid
      }
#      job = Job.new(h_job)
#      job.save
      job.update_attributes(h_job)
    #  project.broadcast step_id
#      job_id_fields = [:parsing_job_id, :filtering_job_id, :normalization_job_id]
#      if step_id < 4
#        o.update_attribute(job_id_fields[step_id-1], job.id)
#      else
#        o.update_attribute(:job_id, job.id)
#      end
      #logger.debug("BLABLABLA")

      Process.waitpid(pid)
      
      #      launch_cmd(cmd, self)                                                                                                                                           
      logger.debug "CMD_STATUS: #{$?.stopped?}" 

      if ! $?.stopped?  #(job and ! $?.stopped?) or (results["original_error"] or results["displayed_error"])
      
        results = {}
        if  File.exists?(output_json)
          begin
            results = JSON.parse(File.read(output_json))
          rescue Exception => e
            results['displayed_error']='Bad format'
            File.open(output_json, 'w') do |f|
              f.write(results.to_json)
            end
          end
        end
  
        ### update duration                                                                                                                                                        
        duration = Time.now - start_time
        if File.exist?(output_file) and !results["original_error"] and !results["displayed_error"]
          job && job.update_attributes(:status_id => 3, :duration => duration)
        else
          job && job.update_attributes(:status_id => 4, :duration => duration)
        end
        
      end
      
#       project.broadcast_new_status
      return job
      
    end

#    def create_job(cmd, project)
#      
#    end
    
    def launch_cmd(command, obj)
       logger.debug("CMD2: " + command)

    pid = spawn(command)
    obj.update_attribute(:pid, pid)
    while 1 do
      alive?(pid)
      sleep 3
    end
  end

#  def alive?(pid)
#    !!Process.kill(0, pid) rescue false
#  end

  def sum(t)
    sum=0
    t.select{|e| e}.each do |e|
      sum+=e
    end
    return sum
  end

  def mean(t)
    sum=0
    t.select{|e| e}.each do |e|
      sum+=e
    end
    return (t.size > 0) ? sum.to_f/t.size : nil
  end

  def median(t1)
    t=t1.select{|e| e}.sort
    n=t.size
    if (n >0)
      if (n%2 == 0)
        return mean([t[(n/2)-1], t[n/2]])
      else
       # puts n/2                                                                                                                           
        return t[n/2]
      end
    else
      return nil
    end
  end

  def safe_download(url, filepath, max_size: nil)
    require 'open-uri'
    #    Error = Class.new(StandardError)                                                                                                                                                                                    
    
    #    DOWNLOAD_ERRORS = [                                                                                                                                                                                                 
    #                       SocketError,                                                                                                                                                                                     
    #                       OpenURI::HTTPError,                                                                                                                                                                              
    #                       RuntimeError,                                                                                                                                                                                    
    #                       URI::InvalidURIError,                                                                                                                                                                            
    #                       Error,                                                                                                                                                                                           
    #                      ]                                                                                                                                                                                                 
    
    url = URI.encode(URI.decode(url))
    url = URI(url)
    raise Error, "url was invalid" if !url.respond_to?(:open)
    
    options = {}
    options["User-Agent"] = "MyApp/1.2.3"
    options[:read_timeout] = 10000
    options[:content_length_proc] = ->(size) {
      if max_size && size && size > max_size
        raise Error, "file is too big (max is #{max_size})"
      end
    }
    
    downloaded_file = url.open(options)
    
    if downloaded_file.is_a?(StringIO)
      # tempfile = Tempfile.new("open-uri", binmode: true)                                                                                                                                                                
      IO.copy_stream(downloaded_file, filepath)
      # downloaded_file = tempfile                                                                                                                                                                                        
      # OpenURI::Meta.init downloaded_file, stringio                                                                                                                                                                      
    end
    
    #   downloaded_file                                                                                                                                                                                                     
    
    #  rescue *DOWNLOAD_ERRORS => error                                                                                                                                                                                
    #    raise if error.instance_of?(RuntimeError) && error.message !~ /redirection/                                                                                                                                    
    #    raise Error, "download failed (#{url}): #{error.message}"                                                                                                                                                           
  end
  

  def std_dev(t)
    t=t.select{|e| e}
    n=t.size
    if (n >0)
      m=mean(t)
      tot=0
      t.map{|e| tot+=(e-m)**2}
      return (tot / n)**0.5
    else
      return nil
    end
  end

  def min(t)
    return t.select{|e| e}.sort.first
  end

  def max(t)
    return t.select{|e| e}.sort.last
  end
end
end
