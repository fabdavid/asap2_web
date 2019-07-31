class ProjectsController < ApplicationController
#  before_action :authenticate_user!, except: [:index]
  before_action :set_project, only: [:show, :edit, :update, :destroy, 
                                     :broadcast_on_project_channel, :live_upd, 
                                     :form_select_input_data, :form_new_analysis,
                                     :parse_form, :parse, :add_metadata, :get_step, :get_pipeline,
                                     :get_run, :get_lineage, :get_step_header,
                                     :autocomplete_genes, :get_rows, :extract_row, :extract_metadata, 
                                     :get_dr_options, :dr_plot, :get_commands, :save_plot_settings,
                                     :confirm_delete_all, :delete_all_runs_from_step,
                                     :get_attributes, :set_input_data, :get_visualization, :replot, :get_file, :upload_file, 
                                     :delete_batch_file, :upload_form, :clone, :direct_download]
  before_action :empty_session, only: [:show]
#  skip_before_action :verify_authenticity_token
  include ApplicationHelper

  def empty_session
    session.delete(:selections)
  end

  def broadcast_on_project_channel
    if APP_CONFIG['authorized_service_keys'].include? params[:service_key] and @project
      @project.broadcast
    end
  end

  def confirm_delete_all
    render :partial => "confirm_delete_all"
  end

  def delete_all_runs_from_step 
    runs = Run.where(:project_id => @project.id, :step_id => params[:step_id]).all
    runs.each do |run|
      RunsController.destroy_run_call(@project, run)
    end
    render :partial => "delete_all_runs_from_step"
  end

  def get_commands

    get_base_data()

    @list_cmds= []
    #    @list_cmds.push("export ASAP_RUN_DIR=./path_to_asap_run")    
    @list_cmds.push("## setting environment variables")
    @list_cmds.push("export ASAP_PROJECTS_DIR=./ ## change this to write your analysis results somewhere else")
    @list_cmds.push("export PROJECT_DIR=$ASAP_PROJECTS_DIR/#{@project.key}")
    @list_cmds.push("")
    #    if parsing_run = Run.where(:project_id => @project.id, :step_id => 'parsing').first and parsing_run.status_id == 3
    operation = "Download initial input file"
    @list_cmds.push("## #{operation}")
    @list_cmds.push("echo '-> #{operation}")
    @list_cmds.push("wget -O $PROJECT_DIR/input.#{@project.extension} #{APP_CONFIG[:server_url]}/projects/#{@project.key}/get_file?filename=input.#{@project.extension}")
    #    end

    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    
    @project.runs.sort.each do |run|
      step = run.step
      step_dir =  project_dir + step.name
      local_step_dir = "$PROJECT_DIR/" + step.name + "/"
      std_method = run.std_method
      h_res = Basic.get_std_method_attrs(std_method, step)
      h_attrs = h_res[:h_attrs]
      h_global_params = h_res[:h_global_params]

      output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      local_output_dir = ((step.multiple_runs == true) ? (local_step_dir + run.id.to_s) : local_step_dir) + "/"
      
      h_cmd = JSON.parse(run.command_json)
      h_cmd['docker_call'].gsub!("-v /srv/asap_run/srv:/srv", "")
      h_cmd['docker_call'].gsub!("/data/asap2:/data/asap2", "$PROJECT_DIR:$PROJECT_DIR")
      h_cmd['time_call'] = nil
      ['opts', 'args'].each do |e|
        h_cmd[e].each_index do |i|
          h_cmd[e][i]['value'] = h_cmd[e][i]['value'].to_s.gsub(project_dir.to_s, "$PROJECT_DIR")
        end
      end
      
      h_attrs.each_key do |k|
        if filename = h_attrs[k]['write_in_file']                                                                                                                         
          filepath = output_dir + filename
          local_filepath = local_output_dir + filename
          operation = "writing file #{local_filepath}"
          @list_cmds.push("## " + operation)
          @list_cmds.push("echo '-> #{operation}'")
          @list_cmds.push("echo '#{File.read(filepath)}' > #{local_filepath}")
        end                                                                                                                                                                \
      end

      operation = "Running #{@h_steps[run.step_id].label}"
      @list_cmds.push("## " + operation)
      @list_cmds.push("echo '-> #{operation}'")
      @list_cmds.push(Basic.build_cmd(h_cmd))
      @list_cmds.push("")

    end

    send_data @list_cmds.join("\n"), :filename => "ASAP_analysis_#{@project.key}.sh"
  end

  def get_base_data
    @h_steps = {}
    @h_step_id_by_name = {}
    @h_steps_by_name = {}
    Step.all.map{|s| @h_steps[s.id]=s; @h_steps_by_name[s.name]=s; @h_step_id_by_name[s.name]=s.id}
    @h_statuses={}
    @h_statuses_by_name = {}
    Status.all.map{|s| @h_statuses[s.id]=s; @h_statuses_by_name[s.name]=s}
#    @h_std_methods = {}
#    StdMethod.all.map{|s| @h_std_methods[s.id] = s}
  end

  def set_lineage_run_ids
    redirect_to :action => 'get_step'
    
  end
  
  def parse
    ### delete all other subsequent analysis    
    Basic.kill_all_runs(@project)
    
    ## parse files
    @project.parse_files
 
    render :nothing => true, :body => nil
  end
  
  def parse_form
    @fu_input = Fu.where(:project_key => @project.key).first
    
    ## get the attributes
    @h_attrs = JSON.parse(@project.parsing_attrs_json)

    render :partial => "form_parsing"
  end
  
  #  def summary
  #    render :partial => 'summary'
  #  end
  
  def get_attr step, std_method
    
    @attrs = []
    
    #  @step = @h_steps[params[:step_id].to_i] #Step.where(:id => h_step[params[:obj_name]]).first                                                                                            
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => step.id).first
    @div_class=nil
    if ['diff_expr', 'clustering'].include? step.name #params[:step_name]                                                                                        
     # @div_class='attr_table'
    elsif ['gene_filtering', 'normalization'].include? step.name #params[:step_name]                                                                    
      @div_class='form-inline'
    end

    #    @obj_inst = StdMethod.find(params[:obj_id])                                                                                                                                             
    h_global_params = JSON.parse(step.method_attrs_json)
    attrs = JSON.parse(std_method.attrs_json)
    ## complement attributes with global parameters - defined at the level of the step                                                                                                       
    #    @log = "bla : #{@attrs.to_json}"
    # if attrs.class != Hash
    #   @log += "bla : #{attrs.to_json}"
    # end
    h_global_params.each_key do |k|
      #     @log += "K : #{k}"
      attrs[k]||={}
      h_global_params[k].each_key do |k2|
        attrs[k][k2] ||= h_global_params[k][k2]
      end
    end
    #    @log += "blou : #{@attrs.to_json}"                                                                                                                                                  
    attr_layout =  JSON.parse(std_method.attr_layout_json)
    return {:attrs => attrs, :attr_layout => attr_layout}
  end

  def form_cell_filtering

    #    depth.json                   detected_genes.json          mitochondrial_content.json   protein_coding_content.json  ribosomal_content.json 
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key 
    json_file = project_dir + 'parsing' + 'output.json'
    loom_file = project_dir + 'parsing' + 'output.loom'
  #  browser = (request.user_agent.match(/Chrome/)) ? 'chrome' : 'other'
    #  browser = 'chrome'
    annot_json_file =  project_dir + 'parsing' + "annot.json"
    compressed_annot_json_file =  project_dir + 'parsing' + "compressed_annot.json"
    compressed_zip_annot_json_file = project_dir + 'parsing' + "compressed_zip_annot.json"
#    compressed_data_file = project_dir + 'parsing' + 'compressed_data.json'

    @h_float = {"mito" => 1, "ribo" => 1, "protein_coding" => 1}
    @h_data = {}
    @h_data_json = nil
    if !File.exist?(compressed_zip_annot_json_file) or File.size(compressed_zip_annot_json_file) == 0 #(browser != 'chrome') ? compressed_annot_json_file : compressed_zip_annot_json_file)
      @h_cmd = {
        "depth" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -light -f #{loom_file} -meta col_attrs/_Depth", 
        "ribo" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 1 -f #{loom_file} -light -meta col_attrs/_Ribosomal_Content",
        "mito" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 1 -f #{loom_file} -light -meta col_attrs/_Mitochondrial_Content",
        "detected_genes" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_file} -light -meta col_attrs/_Detected_Genes",
        "protein_coding" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 1 -f #{loom_file} -light -meta col_attrs/_Protein_Coding_Content"
      }
      
      #      @h_json_data = {}      
      # NO COMPRESSION version
      #      File.open(annot_json_file, "w", encoding: 'ascii-8bit') do |fw|
      #        h_data = {}
      #        @h_cmd.each_key do |k|
      #          tmp_json = `#{@h_cmd[k]}`.gsub(/\n/, '')          
      #          if !tmp_json.empty?
      #            h_data[k] = {'values' => JSON.parse(tmp_json)['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}}
      #          end
      #        end
      #        fw.write(h_data.to_json)
      #      end
      #### SIMPLE PACKING version  
      #  if browser == 'firefox'
      #    File.open(compressed_annot_json_file, "w", encoding: 'ascii-8bit') do |fw| 
      #      
      #      @h_cmd.each_key do |k|
      #        tmp_json = `#{@h_cmd[k]}`.gsub(/\n/, '')
      #        if !tmp_json.empty?
      #          @h_data[k] = {'values' => Base64.encode64(JSON.parse(tmp_json)['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}.pack("S*")).gsub("\n", "") } 
      #        end
      #      end    
      #      fw.write(@h_data.to_json)
      #    end
      #  else
      File.open(compressed_zip_annot_json_file, "w", encoding: 'ascii-8bit') do |fw|
        @h_cmd.each_key do |k|
          tmp_json = `#{@h_cmd[k]}`.gsub(/\n/, '').encode('ASCII', :replace => '0')
          if !tmp_json.empty?
            @h_data[k] = {'values' => Base64.encode64( Zlib::Deflate.deflate(JSON.parse(tmp_json)['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}.pack("S*"))).gsub("\n", "")}
          end
        end
        fw.write(@h_data.to_json)
      end
      #   end

#      File.open(compressed_annot_json, "w", encoding: 'ascii-8bit') do |fw|
#        fw.write(@h_data.to_json)
        #      fw.write("const FastIntegerCompression = require('/srv/FastIntegerCompression.js/node_modules/fastintcompression')\n")
        #     fw.write("const JSONC = require('/srv/asap2/app/JSONC.js')\n")
        #     fw.write("const Base64 = require('/srv/asap2/app/base64.min.js').Base64\n")
        #     fw.write("const gzip = require('/srv/asap2/app/gzip.js')\n")
        #      fw.write("function ab2str(buf) { return String.fromCharCode.apply(null, new Uint8Array(buf));}\n")
        #      fw.write("var h_data = {}\n")
        #      fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| "h_data.#{k} = ab2str(FastIntegerCompression.compress(#{@h_json_data[k]['values'].map{|e| (h_float[k]) ? (e*10).to_i : e}.to_json}));"}.join("\n"))      
        #      fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| "h_data.#{k} = JSONC.pack(#{@h_json_data[k]['values'].to_json}, true)"}.join("\n")) + "\n"
        #      fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| v = Base64.encode64(@h_json_data[k]['values'].map{|e| (h_float[k]) ? (e*10).to_i : e.to_i}.pack('S*')); "h_data.#{k} = \"#{v}\""}.join("\n") + "\n")
        #       fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| "h_data.#{k} = #{@h_json_data[k]['values'].to_json}"}.join("\n") + "\n")
        #    fw.write("console.log(JSONC.pack(h_data, true))")
        #  fw.write("console.log(h_data)")
#      end
    else
# commented to test
#      @h_data = (browser != 'chrome') ? JSON.parse(File.read(compressed_annot_json_file)) : JSON.parse(File.read(compressed_zip_annot_json_file))
     # @h_data = JSON.parse(File.read(annot_json_file))
      if  @project.nber_cols > 20000
        @h_data_json = File.read(compressed_zip_annot_json_file)
      else
        @h_data = JSON.parse(File.read(compressed_zip_annot_json_file))
      end
      #      @h_data_json = File.read(compressed_annot_json)
    end

    @step = Step.where(:name => "cell_filtering").first #@h_steps[params[:step_id].to_i]
    @std_method = StdMethod.where(:step_id => @step.id, :obsolete => false).first
    @h_method_details = get_attr(@step, @std_method)
      
    @annots = Annot.where(:project_id => @project.id, :data_type_id => 3, :dim => 1).all
    @h_annot_runs = {} 
    Run.where(:id => @annots.map{|a| a.run_id}).all.map{|r| @h_annot_runs[r.id] = r}
   
    #    @h_labels = {
    #      :protein_coding => "% protein coding genes",
    #      :ribo => "% ribosomal genes",
    #      :mito => "% mitochondrial genes",
    #      :detected_genes => "detected genes",
    #      :depth => "UMI/reads"
    #    }
    
    @list_p = [
               {:name => "depth", :attr_name => 'depth',  :type => :lower, :threshold => 1000, :label => "UMI/reads"},
               {:name => "detected_genes", :attr_name => 'detected_genes', :type => :lower, :threshold => 1000, :label => "detected genes"},
               {:name => "protein_coding", :attr_name => 'protein_coding_content', :type => :lower, :threshold => 80, :label => "% protein coding genes"},
               {:name => "mito", :attr_name => 'mito_content', :type => :greater, :threshold => 20, :label => "% mitochondrial genes"},
               {:name => "ribo", :attr_name => 'ribo_content', :type => :greater, :threshold => 40, :mito => 20, :label => "% ribosomal genes"}
              ]

    @h_p = {}
    @list_p.each do |e|
      @h_p[e[:type]] ||= {}
      @h_p[e[:type]][e[:name]]={:threshold => e[:threshold]}
    end

    #    @h_p = {
    #      :greater => {
    #        :protein_coding => {:threshold => 80},
    #      },
    #      :lower => {
    #        :depth => {:threshold => 1000},
    #        :detected_genes => {:threshold => 1000},
    #        :ribo => {:threshold => 40},
    #        :mito => {:threshold => 20}
    #      }
    #   }

    # @annots.map{|a| @h_steps[a.step_id]}.uniq.each do |step|
    #   @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    # end

  end
  
  def form_new_analysis
    @log = ''
    get_base_data()

    @step_id = params[:step_id].to_i
    @step = @h_steps[@step_id]    
    @h_step_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? JSON.parse(@step.attrs_json) : {}
    
    ## check applicable methods
    runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
    @std_methods = StdMethod.where(:step_id => @step.id, :obsolete => false).all.sort{|a, b| a.name <=> b.name}
    @h_std_methods_by_name = {}
    @std_methods.map{|s| @h_std_methods_by_name[s.name]=s}
    @h_unavailable_methods = {}
    @std_methods.each do |std_method|
      h_res = get_attr(@step, std_method)
      h_res[:attrs].each_key do |attr_name|
        if  h_res[:attrs][attr_name]['valid_types']
          valid_types = h_res[:attrs][attr_name]['valid_types']
          source_steps = h_res[:attrs][attr_name]['source_steps']
          h_constraints = h_res[:attrs][attr_name]['constraints']
          source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
          tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
          h_res2 = check_valid_types(@step, tmp_runs, valid_types, source_steps, h_constraints)
          #@log += "attr_name: #{attr_name} => " + h_res2[:h_runs].to_json
          
          if h_res2[:h_runs].keys.size == 0
#            @h_unavailable_methods[std_method.id] ||= {}
             @h_unavailable_methods[std_method.id] = h_res2 #[attr_name] = h_res2
          end
        end
      end
    end

    if !@step.has_std_form
     # begin
      eval("form_#{@step.name}()")
     # rescue Exception => e
     #   @error = e.message
     # end
    end
#    @h_runs_by_step = {}

#    @h_res = check_valid_types(runs, @valid_types, @source_steps)
    @req = Req.new

    render :partial => "std_form"

  end

  def check_valid_types step, runs, all_valid_types, source_steps, h_constraints
  
    h_res = {
      :h_attr_outputs => {},
      :valid_step_ids => [],
      :h_runs => {}
    }
    #  source_step_ids = @attrs[params[:attr_name]]['source_steps'].map{|ssn| @h_steps_by_name[ssn].id}.select{|sid| @h_runs_by_step[sid]}.sort{|a,b| @h_steps[a].rank <=> @h_steps[b].rank}                  
#    @log += "valid_types: #{valid_types.to_json}<br/>"
#    @log += "source_steps: #{source_steps.to_json}<br/>"
    #   @source_step_id = params[:source_step_id] || source_step_ids.first                                                                                                                       
 #   @log = ""
    # source_step_ids.each do |sid|                                                                                                                                                            
    nber_criteria = all_valid_types.size 

    ### filter runs with constraints
    if h_constraints and h_constraints['in_lineage']
      constraint_params = h_constraints['in_lineage']
      constraint_datasets = constraint_params.select{|attr_name| s =session[:input_data_attrs][@project.id][step.id.to_s] and s[attr_name]}.map{|attr_name| session[:input_data_attrs][@project.id][step.id.to_s][attr_name]}.flatten.uniq
    #  @log += session[:input_data_attrs].to_json
    #  @log += constraint_params.to_json
      constraint_runs = Run.where(:id => constraint_datasets.map{|e| e["run_id"]}).all
      lineage_constraint_run_ids = constraint_runs.map{|e2| [e2.id] + e2.lineage_run_ids.split(",").map{|e| e.to_i}}.flatten.uniq
      runs = runs.select{|e|
        intersect = e.lineage_run_ids.split(",").map{|e| e.to_i} & lineage_constraint_run_ids
        #  @log +="111 #{e.lineage_run_ids.split(",").to_json} <==> #{lineage_constraint_run_ids.to_json}"                                                                                              
          @log +="#{intersect.size} == #{lineage_constraint_run_ids.size}"
        intersect.size == lineage_constraint_run_ids.size
      }
    end
    
    runs.each do |run|
      sid = run.step_id
      ### add run only if the run has a compatible output                                                                                                                                                     
      h_outputs = JSON.parse(run.output_json)
#      @log+= run.id.to_s + "--->" + h_outputs.to_json
      h_outputs.each_key do |k|
        files = h_outputs[k].keys.select{|k2|
          nber_valid_criteria = 0
          all_valid_types.each do |valid_types|
            @log+= "#{h_outputs[k][k2]['types'].to_json} & #{valid_types.to_json}"
            nber_valid_criteria += 1 if h_outputs[k][k2]['types'] and valid_types and
              (intersect = valid_types & h_outputs[k][k2]['types']) and intersect.size > 0
          end
          @log+=" <#{nber_valid_criteria}-#{nber_criteria}> "
          nber_valid_criteria == nber_criteria
        }
  #      @log += "Data: " + files.to_json + "<br/>"
        if files.size > 0
          h_res[:h_attr_outputs][sid]||={}
          h_res[:h_attr_outputs][sid][run.id]||=[]
          h_res[:h_attr_outputs][sid][run.id] += files.map{|f| [k, f]}
          h_res[:h_runs][run.id]||= run
        end
      end
    end
 #   @log+= "RES: " + h_res.to_json + "<br/>"
    h_res[:valid_step_ids] = source_steps.map{|ssn| @h_steps_by_name[ssn].id}.select{|sid| h_res[:h_attr_outputs][sid]}.sort{|a,b| @h_steps[a].rank <=> @h_steps[b].rank}
 #   @log += "bla: #{h_res[:valid_step_ids]}"
    h_res[:source_step_id] = (params[:source_step_id]) ? params[:source_step_id].to_i : h_res[:valid_step_ids].first
    
    return h_res
  end
  
  def form_select_input_data
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
   # @step = Step.where(:name => params[:step_name]).first

#    source_step_id = (params[:source_step_id]) ? params[:source_step_id].to_i : h_res[:valid_step_ids].first 
    @log = ''
    get_base_data()
    @step = @h_steps[params[:step_id].to_i]
    @obj_inst = StdMethod.find(params[:obj_id])
    h_res = get_attr(@step, @obj_inst)
    @attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]
    @h_constraints =  @attrs[params[:attr_name]]['constraints']     
    @valid_types = @attrs[params[:attr_name]]['valid_types']
    @source_steps = @attrs[params[:attr_name]]['source_steps']
    source_step_ids = @source_steps.map{|ssn| @h_steps_by_name[ssn].id}

    lineage_filter()

    ## TODO integrate filter 
    #available_run_ids = ActiveRun.select("run_id").where(:project_id => @project.id, :step_id => source_step_ids, :status_id => @h_statuses_by_name['success']).all.map{|e| e.run_id}

    #    @log += "AVAILABLE: #{available_run_ids.to_json} <BR/> current_filtered: #{@current_filtered_run_ids.to_json}"
    #    @log += "BAD runs: " + Run.where(:id => @current_filtered_run_ids).to_json 
    #runs = (@current_filtered_run_ids & available_run_ids).map{|run_id| @h_all_runs[run_id]}
    #runs = available_run_ids.map{|run_id| @h_all_runs[run_id]}
    runs = Run.where(:project_id => @project.id, :step_id => source_step_ids, :status_id => @h_statuses_by_name['success']).all

#    ## filter runs based on constraints
#
#    if @h_constraints and @h_constraints['in_lineage']
#      constraint_params = @h_constraints['in_lineage']
#      constraint_datasets = constraint_params.select{|attr_name| session[:input_data_attrs][attr_name]}.map{|attr_name| session[:input_data_attrs][attr_name]}.flatten.uniq
#      constraint_runs = Run.where(:id => constraint_datasets.map{|e| e["run_id"]}).all
#      lineage_constraint_run_ids = constraint_runs.map{|e2| [e2.id] + e2.lineage_run_ids.split(",").map{|e| e.to_i}}.flatten.uniq
#      runs = runs.select{|e| 
#        intersect = e.lineage_run_ids.split(",").map{|e| e.to_i} & lineage_constraint_run_ids
#      #  @log +="111 #{e.lineage_run_ids.split(",").to_json} <==> #{lineage_constraint_run_ids.to_json}"
#        @log +="#{intersect.size} == #{lineage_constraint_run_ids.size}"
#        intersect.size == lineage_constraint_run_ids.size
#      }
#    end

    std_methods = StdMethod.where(:id => runs.map{|r| r.std_method_id}).all
    @h_std_methods = {}
    std_methods.map{|std_method| @h_std_methods[std_method.id] = std_method} 
    @h_runs_by_step = {}
    
    @h_res = check_valid_types(@step, runs, @valid_types, @source_steps,  @h_constraints)

    @h_children_run_ids = {}
    @h_lineage_run_ids = {}

    tmp_h_children = {}
    @h_res[:h_runs].each_key do |run_id|
 #     @h_run_ids_by_step_id
      lineage_run_ids = @h_res[:h_runs][run_id].lineage_run_ids.split(",")      
      @h_lineage_run_ids[run_id] = lineage_run_ids
      lineage_run_ids.each do |parent_run_id|
        tmp_h_children[parent_run_id]||={}
        tmp_h_children[parent_run_id][run_id]=1
      end
    end
    tmp_h_children.each_key do |parent_run_id|
      @h_children_run_ids[parent_run_id] = tmp_h_children[parent_run_id].keys
    end

    ## get run_ids by step_id
    @h_run_ids_by_step_id = {}
    @h_res[:h_attr_outputs].each_key do |sid|
      @h_run_ids_by_step_id[sid] = @h_res[:h_attr_outputs][sid].keys
    end

    ## get std_method details              
    @h_std_method_attrs = get_std_method_details(@h_res[:h_runs].values)

    ## get dashboard cards info for each valid step
    @h_dashboard_card={}
    @h_res[:valid_step_ids].map{|sid| @h_steps[sid]}.each do |step|
      @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    end

    render :partial => 'form_select_input_data'
  end

  def direct_download
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    tmp_dir = project_dir + 'tmp'
    Dir.mkdir(tmp_dir) if !File.exist? tmp_dir
    tmp_file = tmp_dir + 'output.svg'
    File.open(tmp_file, 'w') do |f|
      f.write(params[:data_content])
    end
    cmd = "cairosvg output.svg -o output.pdf" 
    #"rsvg-convert -f pdf -o output.pdf output.svg"
    `#{cmd}`
#    send_file tmp_dir + 'output.svg', type: params[:content_type] || 'application/pdf'
    send_data params[:data_content], type: params[:content_type] || 'text', disposition: (params[:filename]) ? ("attachment; filename=" + params[:filename]) : ''
  end
  
  def get_cart
    @project = Project.where(:key => params[:project_key]).first    
    render :partial => 'cart'
  end

  def get_cells
  
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    cells = File.open(project_dir + 'parsing' + 'output.tab', 'r').gets.chomp.split("\t")
    genes_header = cells.shift
    return cells
    
  end

  def upload_form
  end

  def set_viz_session
    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = params[e]
    end
    #    render :text => session[:viz_params].to_json
  end
  
  def clone_obj p, e, new_dir, ext #, new_dir
    e_new = e.dup
    e_new.project_id = p.id 
    e_new.save
    File.rename(new_dir + (e.id.to_s + ext), new_dir + (e_new.id.to_s + ext))    
    return e_new
  end

  def clone
 
    if exportable? @project #@project.sandbox == false or admin?                                                                                           
      new_project = @project.dup
      if current_user
        new_project.key = create_key()
        new_project.sandbox = false
      else
        if p = Project.where(:key => session[:sandbox]).first and editable? p
          delete_project(p)
        end
        new_project.key = session[:sandbox]
        new_project.sandbox = true
      end
      
      new_project.name += ' cloned'
      new_project.public = false
      new_project.user_id = (current_user) ? current_user.id : 1
      new_project.session_id = (s = Session.where(:session_id => session.id).first) ? s.id : nil
      new_project.cloned_project_id = @project.id
      new_project.parsing_job_id = nil
      new_project.filtering_job_id = nil
      new_project.normalization_job_id = nil
      new_project.save

      ##create user dir if doesn't exist yet                                                                                                               
      new_project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((new_project.user_id == nil) ? '0' : new_project.user_id.to_s)
      Dir.mkdir new_project_dir if !File.exist? new_project_dir
      new_project_dir += new_project.key
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      FileUtils.cp_r project_dir, new_project_dir if project_dir != new_project_dir

      ## copy runs 
      
      h_runs = {}
      @project.runs.each do |run|
        new_run = run.dup
        new_run.project_id = new_project.id
        new_run.save
        h_runs[run.id] = new_run.id
      end

      h_steps = {}
      Step.all.each do |s|
        h_steps[s.id] = s
      end
      
      ## change ids and full_path in all runs 
      new_project.runs.each do |run|
        step = h_steps[run.step_id]
        run_dir = project_dir + step.name
        new_run_dir = new_project_dir + step.name
        if run.step.multiple_runs == true
          run_dir = project_dir + step.name + run.id.to_s
          new_run_dir = new_project_dir + step.name + run.id.to_s
        end

        h_output = JSON.parse(run.output_json)
        new_h_output = {}
        h_output.each_key do |k|
         # keys_to_delete = []
          new_h_output[k]={}
          h_output[k].each_key do |k2|
            l = k2.split(":")
            t = l[0].split("/")
            if t.size == 3 and run_id = t[1]
              t[1] = h_runs[run_id.to_i]
              l[0] = t.join("/")
              new_k2 = l.join(":")
              new_h_output[k][new_k2]=h_output[k][k2].dup              
            end
          end
          #          keys_to_delete.each do |k2|
          #            h_output[k].delete(k2)
          #          end
        end
        new_lineage_run_ids = run.lineage_run_ids.split(",").map{|run_id| h_runs[run_id.to_i]}
        new_parent_run = nil
        if run.run_parents_json
          if parent_run = JSON.parse(run.run_parents_json)
            new_parent_run =[]
            parent_run.each do |p_run|
              new_parent_run.push({:run_id => h_runs[p_run["run_id"]], :type => p_run["type"], :output_attr_name => p_run["output_attr_name"]})
            end
          end
        end
        new_children_run_ids = run.children_run_ids.split(",").map{|run_id| h_runs[run_id.to_i]}
        new_command = JSON.parse(run.command_json)
        t =  new_command['container_name'].split("_").map{|e| (h_runs[e.to_i]) ? h_runs[e.to_i] : e }
        new_command['container_name']= t.join("_")
        new_command['time_call'].gsub!(/#{run_dir.to_s}/, new_run_dir.to_s)
        ['args', 'opts'].each do |k|
          new_command[k].each_index do |i|
            if new_command[k][i]['value'].to_s.match(/\/#{run.id}\//)
              new_command[k][i]['value'].gsub!(/\/#{run.id}\//, "/#{h_runs[run.id]}/")
            end
          end
        end
        new_attrs = JSON.parse(run.attrs_json)
        new_attrs.each_key do |k|
          if new_attrs[k].is_a? Hash
            new_attrs[k]['run_id'] = h_runs[new_attrs[k]['run_id'].to_i]
            t = new_attrs[k]['output_filename'].split("/")
            t[1] = h_runs[t[1].to_i] if t.size == 3
            new_attrs[k]['output_filename'] = t.join("/") 
          end
        end
        run.update_attributes({
                                :attrs_json => new_attrs.to_json,
                                :command_json => new_command.to_json,
                                :output_json => new_h_output.to_json, 
                                :lineage_run_ids => new_lineage_run_ids.join(","), 
                                :run_parents_json => new_parent_run.to_json,
                                :children_run_ids => new_children_run_ids.join(",")
                              })
      end
      
      ## copy files (do not use the fo_id but directly relative path)          
      #  h_fos = {}
      @project.fos.each do |file|
        new_fo = file.dup
        new_fo.project_id = new_project.id
        new_fo.save
        #    h_fos[fo.id] = new_fo.id
      end
      
      ## copy annots
      @project.annots.each do |annot|
        new_annot = annot.dup
        new_annot.project_id = new_project.id
        new_annot.run_id = h_runs[annot.run_id]
        new_annot.store_run_id = h_runs[annot.store_run_id]
        new_annot.save
      end
      
      ## copy project_steps
      @project.project_steps.sort{|a, b| a.updated_at <=> b.updated_at}.map{|e|
        new_e = e.dup
        new_project.project_steps << new_e
      }

      ## copy fus
      @project.fus.map{|e| new_e = e.dup; new_e.update_attribute(:project_key, new_project.key); new_project.fus << new_e}

      @log = ''
      ## rename run folders
      Step.where(:multiple_runs => true).all.each do |s|
        Run.where(:project_id => @project.id, :step_id => s.id).all.each do |r|
          run_dir = new_project_dir + s.name + r.id.to_s
          new_run_dir = new_project_dir + s.name + h_runs[r.id].to_s
          @log += "#{run_dir.to_s} -> #{new_run_dir.to_s}"
          File.rename(run_dir, new_run_dir)
        end
      end

      ## replace input.[extension] by a link (because cannot be changed)                                                                   
      if project_dir != new_project_dir
        File.delete new_project_dir + ('input.' + @project.extension)
        File.symlink project_dir + ('input.' + @project.extension), new_project_dir + ('input.' + @project.extension)
      end
      
      redirect_to :action => 'show', :key => new_project.key
    else
      render :nothing => true
    end

  end
  
  def clone_old

    if exportable? @project #@project.sandbox == false or admin?
      new_project = @project.dup
      if current_user
        new_project.key = create_key()
        new_project.sandbox = false
      else
        if p = Project.where(:key => session[:sandbox]).first and editable? p
          delete_project(p)
        end
        new_project.key = session[:sandbox]
        new_project.sandbox = true
      end
      
      new_project.name += ' cloned'
      new_project.public = false
      new_project.user_id = (current_user) ? current_user.id : 1
      new_project.session_id = (s = Session.where(:session_id => session.id).first) ? s.id : nil
      new_project.cloned_project_id = @project.id
      new_project.parsing_job_id = nil
      new_project.filtering_job_id = nil
      new_project.normalization_job_id = nil      
      new_project.save
      
      #delete exising files if sandbox
      #new_tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((new_project.user_id == nil) ? '0' : new_project.user_id.to_s) + new_project.key
      #if !current_user
      #  FileUtils.rm_r new_tmp_dir if File.exist?(new_tmp_dir)
      #end
      
      ## copy dir                                              
      ##create user dir if doesn't exist yet
      new_tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((new_project.user_id == nil) ? '0' : new_project.user_id.to_s)
      Dir.mkdir new_tmp_dir if !File.exist? new_tmp_dir
      new_tmp_dir += new_project.key
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      FileUtils.cp_r tmp_dir, new_tmp_dir if tmp_dir != new_tmp_dir
      
      
      ## copy object and rename files
      
      h_clusters = {}
      @project.clusters.select{|e| [3,4].include?(e.status_id)}.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'clustering', "")
        new_e.update_attribute(:job_id, nil)
        h_clusters[e.id]=new_e.id
      }


      @project.selections.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'selections', ".txt")
#        if e.selection_type_id == 1
          new_e.update_attribute(:obj_id, h_clusters[e.obj_id])
#        elsif e.selection_type_id == 2
#          
#        end
      }

      h_diff_exprs={}
      @project.diff_exprs.select{|e| [3,4].include?(e.status_id)}.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'de', "")
        h_diff_exprs[e.id]=new_e.id
        new_e.update_attribute(:job_id, nil)
      }

      @project.gene_enrichments.select{|e| [3,4].include?(e.status_id)}.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'gene_enrichment', "")
        new_e.update_attribute(:diff_expr_id, h_diff_exprs[e.diff_expr_id])
        new_e.update_attribute(:job_id, nil)
      }
      @project.project_steps.sort{|a, b| a.updated_at <=> b.updated_at}.map{|e| 
        new_e = e.dup 
        #    new_e.status_id = nil if [1, 2].include?(new_e.status_id) 
        new_project.project_steps << new_e
      }
      @project.fus.map{|e| new_e = e.dup; new_e.update_attribute(:project_key, new_project.key); new_project.fus << new_e}
 
      ## do not clone the jobs that are kept only for stat purpose
      #@project.jobs.select{|e| [3,4].include?(e.status_id)}.sort{|a, b| a.updated_at <=> b.updated_at}.map{|e| new_job = e.dup; new_job.cloned_job_id=e.id; new_project.jobs << new_job}
      
      #    psteps = new_project.project_steps.sort{|a, b| a.step_id <=> b.step_id}
      #    psteps.each_index do |i|
      #      ps = psteps[i]
      #      if [1,2].include?(ps.status_id)
      #        ps.status_id = nil
      #      end
      #    end
      h_genesets = {}
       @project.gene_sets.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'gene_sets', ".txt")
        h_genesets[e.id]=new_e.id
        new_e.update_attribute(:ref_id, h_diff_exprs[e.ref_id])
        #  new_project.gene_sets << e.dup
      }

      @project.project_dim_reductions.map{|e|
        new_e = e.dup
        h_attrs_json = JSON.parse(new_e.attrs_json)
        h_attrs_json['custom_geneset'] = h_genesets[h_attrs_json['custom_geneset']] if h_attrs_json['custom_geneset']
        status_id = e.status_id
        status_id = nil if status_id and status_id < 3
        new_e.update_attributes({:status_id => status_id, :job_id => nil, :attrs_json => h_attrs_json.to_json})        
        new_project.project_dim_reductions << new_e
      }

      ## replace input.[extension] by a link (because cannot be changed)
      if tmp_dir != new_tmp_dir
        File.delete new_tmp_dir + ('input.' + @project.extension)
        File.symlink tmp_dir + ('input.' + @project.extension), new_tmp_dir + ('input.' + @project.extension)
      end
      
      redirect_to :action => 'show', :key => new_project.key
    else
      render :nothing => true
    end
  end

  def delete_batch_file
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]    
    File.delete(tmp_dir + "parsing" + "group.tab") if File.exist?(tmp_dir + "parsing" + "group.tab")
    File.delete(tmp_dir + "group.txt") if File.exist?(tmp_dir + "group.txt")
    render :partial => "edit"
  end
  
  def set_viz_attrs(pdr)
     if pdr and pdr.attrs_json
      h_attrs = JSON.parse(pdr.attrs_json)
      @attrs.each_index do |i|
        logger.debug("DEFAULT" + @attrs[i]['name'].to_json + "->" + h_attrs[@attrs[i]['name']].to_json)
        @attrs[i]['default']=h_attrs[@attrs[i]['name']]
      end
    end    
  end

  def get_data_for_viz(dr_id)
    @h_dim_reductions={}
    DimReduction.all.map{|s| @h_dim_reductions[s.id]=s}
    @form_inline = 1 ### to display attributes on one line                                                                                                                     
    @attrs = JSON.parse(@h_dim_reductions[dr_id].attrs_json)
    @dim_reduction = DimReduction.where(:id => dr_id).first
    pdr = ProjectDimReduction.where(:project_id => @project.id, :dim_reduction_id => dr_id).first
    if !pdr
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      output_dir = project_dir + 'visualization'
      visualization_dir = output_dir + @dim_reduction.name
      Dir.mkdir(visualization_dir) if !File.exist?(visualization_dir)
      pdr = ProjectDimReduction.new(:project_id => @project.id, :dim_reduction_id => dr_id, :user_id => (current_user) ? current_user.id : 1)
      pdr.save
    end
    @active_item_name = (session[:active_dr_id]) ? @h_dim_reductions[session[:active_dr_id]].label.downcase : 'PCA'
    return pdr
  end

  def rerun_dim_reduction(pdr)
    h_attrs = params[:attrs]
    #    heatmap_key_to_delete = nil
    #    if h_attrs[:geneset_type] == 'global'
    #      heatmap_key_to_delete = 'custom_geneset'
    #    elsif h_attrs[:geneset_type] == 'custom'
    #      heatmap_key_to_delete = 'global_geneset'
    #    end
    #    h_attrs.delete(heatmap_key_to_delete) if heatmap_key_to_delete
    pdr.update_attributes(:status_id => 1, :attrs_json => (h_attrs) ? h_attrs.to_json : {})
    logger.debug("RUN!!" + pdr.id.to_s + " " + params[:attrs].to_json)
    dr = pdr.dim_reduction

    job = Basic.create_job(pdr, 4, @project, :job_id, dr.speed_id)
    ###########  pdr.delay(:queue => (dr.speed) ? dr.speed.name : 'fast').run
    delayed_job = Delayed::Job.enqueue ProjectDimReduction::NewVisualization.new(pdr, params[:attrs][:sub_step]), :queue => (dr.speed) ? dr.speed.name : 'fast'
    job.update_attributes(:delayed_job_id => delayed_job.id) #job.id)    
   # pdr.run params[:attrs][:sub_step]
  end

  def get_last_update_status
    jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => [1, 2, 3, 4]).all.to_a
    jobs.sort!{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')} if jobs.size > 0
    last_job = jobs.last
    last_update = @project.status_id.to_s + ","
    last_update += [jobs.size, last_job.status_id, last_job.id, last_job.updated_at].join(",") if last_job
    return last_update
  end

  def live_upd
    render :partial => 'live_upd'
  end

  def get_pipeline
    @redirect_to_main_page=nil
  
    if @project
      @h_statuses={}
      Status.all.map{|s| @h_statuses[s.id]=s}

      @last_update = get_last_update_status()

      #      @active_step_pending_jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => 1).all

#      h_obj = {
#        5 => Cluster,
#        6 => DiffExpr,
#        7 => GeneEnrichment
#      }
#      obj = h_obj[session[:active_step]]

      counts = [0, 0, 0]
      @positions = [{}, {}, {}]
      all_pending = Job.where(:status_id => 1).order("id").all
      (0 .. all_pending.size-1).to_a.each do |i|
        job = all_pending[i]
        counts[job.speed_id-1]+=1
        if job.project_id == @project.id 
          @positions[job.speed_id-1][job.id]= counts[job.speed_id-1]
        end
      end

      if session[:last_update_active_step].to_s != @last_update.to_s or session[:to_update] == 1  #!=@project.project_steps.to_json or session[:last_step_status_id] != @project.status_id or session[:last_step_id] != @project.step_id
        session[:to_update]=1
        #  @reload_step_container = 1 
        #      session[:last_step_status_id] = @project.status_id
        #      session[:last_step_id] = @project.step_id
        #      session[:project_steps]=@project.project_steps.to_json
        #        session[:reload_step] = 1
        session[:last_update_active_step] = @last_update
      end
      
#      if session[:to_update]==1
#        @reload_step_container = 1
#      end
    else
      @redirect_to_main_page = 1
    end
    render :partial => 'pipeline_upd2'
    
  end
  
  def get_viz_data(tmp_dir)
    @data_json = File.read(tmp_dir + 'output.json')
    @h_ori_data = JSON.parse(@data_json)
    @h_data={'text' => @h_ori_data['text']}
    session[:viz_params]['dim3']='1' if !@h_ori_data["PC" + (params[:dim3] || session[:viz_params]['dim3'].to_s)]
    @h_data['x']=@h_ori_data["PC" + (params[:dim1] || session[:viz_params]['dim1'].to_s)]
    @h_data['y']=@h_ori_data["PC" + (params[:dim2] || session[:viz_params]['dim2'].to_s)]
    @h_data['z']=@h_ori_data["PC" + (params[:dim3] || session[:viz_params]['dim3'].to_s)] #if params[:plot_type]=='3d'
 
  end

  #  def get_visualization
  #  
  #    pdr = get_data_for_viz(params[:active_item].to_i)
  #    set_viz_attrs(pdr)
  #    session[:active_dr_id] = params[:active_item].to_i if params[:active_item]
  #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'visualization' +  pdr.dim_reduction.name 
  #    if pdr and File.exist?(tmp_dir + 'output.json')
  #      get_viz_data(tmp_dir)
  #    else
  #      @button = "<button id='reset_visualization_" + params[:active_item] + "' class='replot btn btn-primary' style=''>Plot</button>"
  #    end
  #    @traces = (@h_data) ? {'2d' => [{'x' => @h_data['x'], 'y' => @h_data['y'], 'text' => @h_data['text']}], '3d' => [@h_data]} : {'2d' => [], '3d' => []}
  #    render :partial => 'visualization_layout'
  #  end
  
  def create_traces(h_results, trace_names)
  
    traces = []
    @h_data['text'].each_index do |i|
     
      text =  @h_data['text'][i]
      if h_results[text]
        x = @h_data['x'][i]
        y = @h_data['y'][i]
        z = @h_data['z'][i]
        cluster_id = h_results[text] -1 
        
        traces[cluster_id]||={'x' => [], 'y' => [], 'z' => [], 'text' => []}
        traces[cluster_id]['x'].push(x)
        traces[cluster_id]['y'].push(y)
        traces[cluster_id]['z'].push(z)
        traces[cluster_id]['text'].push(text)
        traces[cluster_id]['name'] = trace_names[cluster_id] if trace_names
      end
    end
    return traces
  end

  def replot

    @h_batches={}
    @heatmap_json =nil
    @corr_plot_json=nil
    @trajectory_plot_json=nil
    @heatmap_branches_json=[]
    @gene_expression_branches_json=[]

    get_batch_file_groups()
    @list_batches = @h_batches.keys.sort
    @list_val = nil
    @message = ''
    
    params.delete(:full_screen) if params[:full_screen] == ''
    
    @pdr = get_data_for_viz(params[:dr_id].to_i)

    if @pdr
      
      session[:active_dr_id] = (params[:active_item]) ? params[:active_item].to_i : params[:dr_id].to_i
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      tmp_dir = project_dir + 'visualization' +  @pdr.dim_reduction.name
      logger.debug("RERUN! #{params[:attrs].to_json} #{@pdr.attrs_json}")
 
#      params[:attrs][:dataset] = params[:dataset] if params[:dataset]

      if params[:attrs] 
    
        ### clean params       
        
        heatmap_key_to_delete = nil
        if params[:attrs][:geneset_type] == 'global'
          heatmap_key_to_delete = 'custom_geneset'
        elsif params[:attrs][:geneset_type] == 'custom'
          heatmap_key_to_delete = 'global_geneset'
        end
        params[:attrs].delete(heatmap_key_to_delete) if heatmap_key_to_delete
        
        ### determine if the current view is done with the same parameters, if not, restart it                                                                               
        #h_tmp_attrs = JSON.parse(@pdr.attrs_json)
        
        #logger.debug("blabla: " + " : " + @pdr.to_json)
  #      if params[:attrs].to_json != @pdr.attrs_json and !params[:active_item]
        # if    (!params[:attrs][:dim1] and (!@pdr.status_id or [4,5].include?(@pdr.status_id))) or (params[:attrs].to_json != @pdr.attrs_json and !params[:active_item])
        if (!params[:attrs][:dim1] and (!@pdr.status_id or [4,5].include?(@pdr.status_id)) and @pdr.dim_reduction_id < 5) or (params[:attrs].to_json != @pdr.attrs_json and !params[:active_item]) #or params[:dataset] != h_tmp_attrs['dataset']
          
          #logger.debug("blabla 2: " + params[:attrs][:dim1] + " : " + @pdr.to_json)
          if analyzable?(@project) and (@pdr.dim_reduction_id < 5 or owner?(@project))
            #  logger.debug("blabla 3")
            logger.debug("RERUN2! #{params[:attrs].to_json} #{@pdr.attrs_json}")
            File.delete tmp_dir + 'output.json' if File.exist? tmp_dir + 'output.json'
            rerun_dim_reduction(@pdr)
          end
        end
        
      end
      
      if @pdr.dim_reduction_id < 5
        standard_plot(@pdr, project_dir)
      elsif @pdr.dim_reduction_id == 5
        heatmap_plot(@pdr, project_dir)
      elsif @pdr.dim_reduction_id == 6
        correlation_plot(@pdr, project_dir)  
      elsif @pdr.dim_reduction_id == 7
        trajectory_plot(@pdr, project_dir)
      end
    end
    
    if params[:full_screen] 
      render :partial => 'full_screen_visualization_layout'
    else
      render :partial => 'visualization_layout'
    end
  end

  def trajectory_plot(pdr, project_dir)
    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name
    @pdr_params = (pdr.attrs_json) ? JSON.parse(pdr.attrs_json) : {}
    @cells = get_cells().map{|e| [e, e]}
    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = @pdr_params[e]
    end
    @trajectory_exists = File.exist?(tmp_dir + 'monocle_trajectory.json')
    #  if @trajectory_plot_exists
    #    @trajectory_plot_json = File.read(tmp_dir + 'monocle_trajectory.json')
    #  end
    # Dir.glob(tmp_dir + 'monocle_heatmap_branch_*.json').sort.each { |filename|
    #   @heatmap_branches_json.push(File.read(filename).html_safe)
    # }
    # Dir.glob(tmp_dir + 'monocle_geneexpression_branch_*.json').sort.each { |filename|
    #   @gene_expression_branches_json.push(File.read(filename).html_safe)
    # }
    #@button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>"
  end

  def correlation_plot(pdr, project_dir)
    
    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name

    @pdr_params = JSON.parse(pdr.attrs_json) #: {}
    @cells = get_cells().map{|e| [e, e]}
    @h_ori_data = {}
    if File.exist?(tmp_dir + 'output.json')
      @corr_plot_json = File.read(tmp_dir + 'output.json')
      @corr_plot_json = nil if @heatmap_json == ''
    end
#    @button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>"
    
  end

  def heatmap_plot(pdr, project_dir)

    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name

    @pdr_params =  JSON.parse(pdr.attrs_json)

    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = @pdr_params[e]
    end

    @geneset_names=[]

    ### get data                  
    if File.exist?(tmp_dir + 'output.json')
      @data_json = File.read(tmp_dir + 'output.json')
      @h_ori_data = JSON.parse(@data_json)
    end

    if File.exist?(tmp_dir + 'output.heatmap.json')                                           
      @heatmap_json = File.read(tmp_dir + 'output.heatmap.json')
      @heatmap_json = nil if @heatmap_json == ''
    end    
     @button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>" if owner? @project
  end

  def standard_plot(pdr, project_dir)

    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name
    
    traces = nil

    ### write parameters in session
    ['dim1', 'dim2', 'dim3', 'color_by', 'gene_text', 'dataset', 'cluster_id', 'selection_id'].each do |e|
      session[:viz_params][e]=params[e.intern] if params[e.intern]
    end
        
    ### get data
    if File.exist?(tmp_dir + 'output.json')
      get_viz_data(tmp_dir)
    else
      @button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>"
    end
    
    ### get gene expression data for a given gene
    if params[:color_by] == 'gene_text' and params[:gene_text] and params[:gene_text] != ''
      ensembl_ids = params[:gene_text].split(" ").first
      h_ensembl_ids = {}
      ensembl_ids.split(",").map{|e| h_ensembl_ids[e] = 1}
      #gene = Gene.where(:ensembl_id => params[:gene_text].split(" ").first).first
      list_genes = JSON.parse(File.read(project_dir + 'parsing' + 'gene_names.json')) 
      i = 0
      catch (:done) do
        list_genes.each do |e|
          e[1].split(",").each do |ensembl_id|
            throw :done if h_ensembl_ids[ensembl_id]
          end
          e[0].split(",").each do |input_gene_name|
            throw :done if h_ensembl_ids[input_gene_name]
          end
          i+=1
        end
      end
      h_header = {}
      @i = i
      logger.debug("GET_COLOR: #{@i} " + (project_dir + params[:dataset] + 'output.tab').to_s)
      File.open(project_dir + params[:dataset] + 'output.tab', 'r') do |f|
        header = f.gets
        header.chomp!
        t_h = header.split("\t")
        t_h.shift
        while(l = f.gets) do
          l.chomp!
          t = l.split("\t").map{|e| e.to_f}
          k = t.shift
          if k.to_i == i
            h_data = {}
            t.each_index{|i| h_data[t_h[i]]=t[i]}
            @list_val = []
            @h_data['text'].each do |k2|
              @list_val.push(h_data[k2])
            end
            break
          end
        end
      end
      
      traces = [@h_data]
      @message = 'Data not found for this gene (filtered out). You can plot the Original Data instead.' if !@list_val
    elsif params[:color_by] == 'batch_group_list'
      h_batches = {}
      trace_names = []
      @list_batches.each_index do |i|
        k = @list_batches[i]
        trace_names[i]="Group #{k}"
        @h_batches[k].each do |e|
          h_batches[e]=i+1
        end
      end
      traces = create_traces(h_batches, trace_names)
      
    elsif  params[:color_by] == 'clustering_list'
      
      filename = project_dir + 'clustering' + params[:cluster_id] + "output.json"
      h_results = JSON.parse(File.read(filename)) if File.exist?(filename)
      trace_names = (1 .. h_results['clusters'].keys.size).to_a.map{|e| "Cluster #{e}"}
      # @trace_names= trace_names
      traces = create_traces(h_results['clusters'], trace_names)
      
    elsif  params[:color_by] == 'selection_list'
      
      filename = project_dir + 'selections' + "#{params[:selection_id]}.txt"
      #      h_results = JSON.parse(File.read(filename)) if File.exist?(filename)      
      list_cells = File.read(filename).split("\n")
      h_cells = {}      
      list_cells.map{|e| h_cells[e]=1}
      traces = create_traces(h_cells, nil)
      #    compl_data = {'x' => [], 'y' => [], 'z' => [], 'text' => [], 'marker' => {'color' => (1 .. list_cells.size).to_a.map{|i| 1}}}
      
      traces[0]['marker']={'color'=>(1 .. traces[0]['x'].size ).map{|i| 1}}
      
      @h_data['x'].each_index do |i|
        if ! h_cells[@h_data['text'][i]]
          ['x', 'y', 'z', 'text'].each do |k|
            traces[0][k].push(@h_data[k][i])
          end
          traces[0]['marker']['color'].push(0)
        end
      end
      #      traces.push(compl_data)
      #      if traces[0]
      #        traces[0]['marker']={'color'=>(1 .. traces[0]['x'].size ).map{|i| 0}}
      #      end
    else
      traces = [@h_data]
    end
    
    ##create traces_2d
    traces_2d = []
    traces.each_index do |i|
      if traces[i]
        traces_2d[i]= {'x' => traces[i]['x'], 'y' => traces[i]['y'], 'text' => traces[i]['text']}
      end
    end
    
    
    @traces = {'2d' => traces, '3d' => traces}
    
    @nber_points = 0
    traces.each do |trace|
      @nber_points += trace['x'].size if trace and  trace['x']
    end
    
    set_viz_attrs(pdr)
    

  end
  
  def get_results
    
    t = [:parsing, :filtering, :normalization]
#    step_id = params[:step_id].to_i || session[:active_step].to_i
    (1 .. @step.id).each do |i|
      step_name = t[i-1]
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + step_name.to_s              
      filename = tmp_dir + "output.json"       
      if @project.step_id >= i and File.exist?(filename)
        results_json = File.open(filename, 'r').read #lines.join("\n")                                                                                       
        begin
          @all_results[step_name] = JSON.parse(results_json)
        rescue Exception => e
        end
      end
    end
    @results = @all_results[t[@step_id-1]]
  
  end
  
  def get_batch_file_groups
    batch_file = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'parsing' + 'group.tab'
    if File.exist?(batch_file)
      File.open(batch_file, "r") do |f|
        header = f.gets
        while(l = f.gets)
          t = l.chomp.split("\t")
          if t.size == 2
            @h_batches[t[1]]||=[] 
            @h_batches[t[1]].push(t[0])
          end
        end
      end
    end
  end

  def get_lineage
    
    @h_std_methods = {}
    StdMethod.all.map{|s| @h_std_methods[s.id] = s}
    
    get_base_data()
    
    list_cards = []
    run_ids = [params[:run_id].to_i]
    if params[:run_id]
      run = Run.where(:project_id => @project.id, :id => params[:run_id]).first
      if run and run.lineage_run_ids
        run_ids += run.lineage_run_ids.split(",").map{|e| e.to_i} #Run.where(:project_id => @project.id, :id => run.lineage_run_ids.split(",")).all 
      end
    end
    @list_runs =  Run.where(:project_id => @project.id, :id => run_ids).all.order(:id)
    h_runs = {}
    @list_runs.each do |run|
      h_runs[run.id]=run
    end
    @step = @h_steps[h_runs[params[:run_id].to_i].step_id]
    list_cards = create_run_cards(@list_runs)
    
    render :partial => 'display_card_deck', :locals => {:cards => list_cards}
    
  end

  def autocomplete_genes
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @to_render = []
    limit = 100
    if params[:annot_id]
      @annot = Annot.where(:id => params[:annot_id]).first
      if @annot
        #        @h_annots[key]
        ##["/row_attrs/Gene", "/row_attrs/Accession"].each do |annot_name|
        #genes_annot = Annot.where(:store_run_id => @annot.store_run_id, :name => annot_name).first
        
        ### ensembl_ids present in the dataset
#        annot_name = "/row_attrs/Accession"
#        key = annot_name.split("/")[2].downcase
#        loom_path =  project_dir + @annot.filepath
#        @cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -f #{project_dir + 'parsing/output.loom'} -meta #{annot_name}"
#        logger.debug("CMD: " + @cmd)
#        @cmd2 = "java -jar lib/ASAP.jar -T ExtractMetadata -f #{loom_path} -meta /row_attrs/_StableID"
        h_present_ensembl_ids = {}
#        h_meta = JSON.parse(`#{@cmd}`)
#        h_meta_stable_ids = JSON.parse(`#{@cmd2}`)
#        h_meta_stable_ids['values'].each_index do |i|
#          h_present_ensembl_ids[h_meta['values'][h_meta_stable_ids['values'][i]]]||= []
#          h_present_ensembl_ids[h_meta['values'][h_meta_stable_ids['values'][i]]].push(h_meta_stable_ids['values'][i])
#        end
        
        ## do the queries
        @genes = Gene.select("ensembl_id, name, alt_names").where(["organism_id = ? and (lower(name) ~ ? or lower(ensembl_id) ~ ?)", @project.organism_id, "^#{params[:q].downcase}", "^#{params[:q].downcase}"]).all
        @genes |= Gene.select("ensembl_id, name, alt_names").where(["organism_id = ? and lower(alt_names) ~ ?", @project.organism_id, params[:q].downcase]).all.select{|g| 
          t = g.alt_names.split(",")
          t.map{|e| (e.match(/^#{params[:q]}/)) ? 1 : nil}.compact.size > 0
        }
        
        @genes.first(limit).sort{|a, b| a.name <=> b.name}.each do |g|
          if  h_present_ensembl_ids[g.ensembl_id]
            h_present_ensembl_ids[g.ensembl_id].each do |pos|         
              @to_render.push({:label => g.name + ((!g.alt_names.empty?) ? " (#{g.alt_names})" : "") + " [#{g.ensembl_id}] {#{pos}}", :idx => pos})
            end
          end
        end

      else
        @to_render.push({:lable => "Error"})
      end
    else
      @to_render.push({:lable => "Error"})
    end
    respond_to do |format|
      format.json {
      render :text => @to_render.first(limit).to_json
      }
    end
  end

  def extract_metadata
    
    if readable?(@project) and params[:annot_id]
      @annot = Annot.where(:id => params[:annot_id]).first
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      loom_file = project_dir + @annot.filepath
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -light -f #{loom_file} -meta #{@annot.name}"
      send_data `#{cmd}`,  type: params[:content_type] || 'text', disposition: (!params[:display]) ? ("attachment; filename=" + @project.key  + "_" + @annot.filepath.gsub("/", "_")  + @annot.name.gsub("/", "_") + ".json") : ''
    end
  end


  def extract_row(occ)
    row = nil 
    
    if readable? @project  and annot_id = session[:dr_params][@project.id][:annot_id]
      @annot = Annot.where(:id => annot_id).first
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      loom_path = project_dir + @annot.filepath
      
      if occ 
        occ_k = ("occ_" + occ).to_sym
        s = session[:dr_params][@project.id][occ_k]
        
        if s[:data_type] == "1" and s[:dataset_annot_id] and s[:row_i]
          @dataset_annot = Annot.where(:id => s[:dataset_annot_id]).first
          
          # run = Run.where(:project_id => @project.id, :id => params[:annot_id])
          #  h_outputs = JSON.parse(run.output_json)
          #  output_matrix = nil
          #  h_outputs.each_key do |k|
          #    h_outputs[k].each do |e|       
          #    end
          #  end
          
          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractRow -prec 2 -i #{s[:row_i]} -f #{loom_path} -iAnnot #{@dataset_annot.name}"
          row_txt = `#{@cmd}`
          row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['row'] : nil
          
        elsif s[:data_type] == "2" and s[:num_annot_id] and s[:header_i]
          @num_annot = Annot.where(:id => s[:num_annot_id]).first
          row = ['bla']
          if @num_annot.dim == 1 
            # col =>  ExtractCol
            if @num_annot.nber_rows == 1
              @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 2 -light -f #{loom_path} -meta #{@num_annot.name}"
              row_txt = `#{@cmd}`
              row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['values'].map{|e| e.to_f} : nil
            else
              @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -i #{s[:header_i]} -f #{loom_path} -iAnnot #{@num_annot.name}"
              row_txt = `#{@cmd}`
              row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['col'] : nil
            end
            #          row= [@cmd]
            # else
            # row => 
            #  @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractRow -i #{params[:row_i]} -f #{loom_path} -iAnnot #{@dataset_annot.name}"
          end
          #      elsif s[:coloring_type] == '3'
          
        end
        #      row = ['blou']
     # end
     #  row = ['blu']
      elsif session[:dr_params][@project.id][:coloring_type] == '3' and cat_annot_id = session[:dr_params][@project.id][:cat_annot_id] ## cat
      
      @cat_annot = Annot.where(:id => cat_annot_id).first
     # row = ['bla']
    #  if @cat_annot.dim == 1
        # col =>  ExtractCol                                                                                                                                                                                                                 
        if @cat_annot.nber_rows == 1
          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -light -f #{loom_path} -meta #{@cat_annot.name}"
          row_txt = `#{@cmd}`
          row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['values'].map{|e| e.to_f} : nil
          
        else
          #        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -i #{s[:header_i]} -f #{loom_path} -iAnnot #{@cat_annot.name}"
          #        row_txt = `#{@cmd}`
          #        row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['col'] : nil
        end
        #  end
        #        row = [@cmd]
      else
        # row = ['blo']
      end
      #   respond_to do |format|
      #     format.json {
      #       render :text => @row.to_json
      #     }
    #   end
      # row = ['bla']
    end
    return row
  end

  def get_rows
    @rows = []
    [:annot_id, :coloring_type, :cat_annot_id].each do |k|
      if params[k]
        session[:dr_params][@project.id][k] = params[k]
      end
    end
    if params[:occ]
#      @rows = ['bla']
      occ_k = ("occ_" + params[:occ]).to_sym
      [:gene_selected, :dataset_annot_id, :row_i, :data_type, :header_i, :num_annot_id].each do |k|
        if params[k]
          session[:dr_params][@project.id][occ_k]||={}
          session[:dr_params][@project.id][occ_k][k] = params[k]
        end
      end
    
      if session[:dr_params][@project.id][:coloring_type] == "1"
        if row = extract_row("1")
          @rows.push row
          #          @rows.push session[:dr_params][@project.id][:coloring_type]
        end
      elsif session[:dr_params][@project.id][:coloring_type] == "2"
        ["2", "3", "4"].each do |i|
          if  row = extract_row(i)
            @rows.push row
          end
        end
      end
    elsif params[:coloring_type] == '3' ## categorical
 #      @rows = ['bla']
      if row = extract_row(nil)
        @rows = [row]
      end
    end

#    respond_to do |format|                                                                                                                                                                                    
#      format.json {                                                                                                                                                                                           
#        render :text => rows.to_json                                                                                                                                                                          
#      }                                                                                                                                                                                                       
#    end        
  end

  def save_plot_settings
    [:dot_opacity, :dot_size, :coloring_type].each do |k|
      session[:dr_params][@project.id][k] = params[k] if params[k]
    end
  end
  
  def get_dr_options

    get_base_data()

    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @annot = nil
    @datasets = []
    @autocomplete_json = ''
    @log4 = ''
    @num_annots = []
    @cat_annots = []
    if readable?(@project) and params[:run_id]
      @run = Run.where(:id => params[:run_id]).first
      @annot = Annot.where(:project_id => @project.id, :run_id => params[:run_id]).first
     
      @h_attrs = JSON.parse(@run.attrs_json)
      @h_annots = {}
      
      all_runs = []
      store_run = Run.where(:id => @annot.store_run_id).first
      source_run = Run.where(:id => @h_attrs['input_matrix']['run_id']).first
      occ_k = :occ_1 #("occ_" + params[:occ]
      if s = session[:dr_params][@project.id][occ_k]
        s[:dataset_annot_id] = source_run.id
        @datasets = Annot.where(:project_id => @project.id, :store_run_id => store_run.id, :dim => 3).all
        h_datasets = {}
        @datasets.map{|d| h_datasets[d.run_id]=d}
        if  h_datasets[source_run.id]
          s[:dataset_annot_id] =  h_datasets[source_run.id].id
          
          @num_annots = Annot.where(:project_id => @project.id, :data_type_id => 1, :dim => 1, :store_run_id => @annot.store_run_id).all.select{|a| a.nber_rows and a.nber_rows < 200}
          @cat_annots = Annot.where(:project_id => @project.id, :data_type_id => 3, :dim => 1, :store_run_id => @annot.store_run_id).all
          @num_annot = nil
          if annot_id = session[:dr_params][@project.id][:annot_id]
            @num_annot = Annot.where(:project_id => @project.id, :id => annot_id).first
          end
          
          ### prepare JSON file for searching genes
          store_run_step = store_run.step
          autocomplete_file = project_dir + store_run_step.name
          autocomplete_file += store_run.id.to_s if store_run_step.multiple_runs == true
          autocomplete_file += 'autocomplete_genes.json'
          if !File.exists? autocomplete_file
            
            ### retrieve data from loom
            
            annot_names = ["/row_attrs/Gene", "/row_attrs/Accession", "/row_attrs/_StableID"]
            annot_names.each_index do |i|
              annot_name = annot_names[i]
              key = annot_name.split("/")[2].downcase  
              @genes_annot = Annot.where(:store_run_id => @annot.store_run_id, :name => annot_name).first
              
              loom_path = project_dir + @genes_annot.filepath
              @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -light -f #{loom_path} -meta #{annot_name}"
              @log4 += "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -light -f #{loom_path} -meta #{annot_name}" 
              val = `#{@cmd}`
              h_res = (val.match(/^\{/)) ? JSON.parse(val) : {} 
              @h_annots[key] = h_res['values'] 
            end
            
            ### get alt names from database
            h_alt_names = {}
            accessions = @h_annots['accession'].uniq
            h_search = {:organism_id => @project.organism_id}
            if accessions.size < 65000
              h_search[:ensembl_id] = accessions
            end
            Gene.select("ensembl_id, alt_names").where(h_search).all.each do |g|
              h_alt_names[g.ensembl_id] = g.alt_names 
            end
            
            autocomplete_list = []
            h_indexes = {}
            if @h_annots["accession"]
              @h_annots["accession"].each_index do |i|
                h_indexes[@h_annots["_stableid"][i]] = i
                alt_names = h_alt_names[@h_annots["accession"][i]]
                str = [@h_annots["gene"][i], ((@h_annots["accession"][i] != '') ? @h_annots["accession"][i] : nil), ((alt_names and alt_names != '') ? "[#{alt_names}]" : nil), "{#{@h_annots["_stableid"][i]}}"].compact.join(" ")
                autocomplete_list.push str #@h_annots["_stableid"][i]
              end
            end
            @autocomplete_json = {"search" => autocomplete_list.sort, "h_indexes" => h_indexes}.to_json
            
            if autocomplete_list.size > 0 and h_indexes.keys.size > 0
              File.open(autocomplete_file, 'w') do |f|
                f.write(@autocomplete_json)
              end
            end
          else
            @autocomplete_json = File.read(autocomplete_file)
          end
        end
      end
    end
    render :partial => 'dim_reduction_options'
  end


  def dr_plot
    @h_data = {}
    @run = nil
    @row = nil
    if run_id = params[:plot][:run_id]
      @run = Run.where(:id => run_id).first
      h_outputs = JSON.parse(@run.output_json)
      
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      
      dataset = nil
      loom_file = ''
      h_outputs['output_annot'].keys.each do |output_key|
        t = output_key.split(":")
        if t.size > 1
          loom_file = t[0]
          dataset = t[1]
        end
      end
      if dataset
        #t2 = dataset.split("/")
        
        loom_path = project_dir + loom_file
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_path} -meta #{dataset}"
        
        #        @h_data = {}
        # @h_cmd.each_key do |k|
        @h_json_data= `#{@cmd}` #.split("\n")[2] #gsub(/^.+?\{/, '{')     
      end
    end
    
#    if session[:global_dr_params][@project.id][:coloring_type] == "1" and 
#      params[:occ] = '1'
#    extract_row("1")
#    end

    if params[:partial] 
      render :partial => params[:partial]
    else
      render :partial => "dim_reduction_plot"
    end
  end

  def get_run_dim_reduction
    
  end

  def get_dim_reduction_form
    render :partial => "dim_reduction_form"
  end

  def get_run

    #@h_steps={}
    #Step.all.map{|s| @h_steps[s.id]=s}
    #@h_statuses={}
    #Status.all.map{|s| @h_statuses[s.id]=s}
    get_base_data()

    ## define output_dir                                                                                                                                                                                          
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      
    @run = Run.where(:id => params[:run_id]).first
    @step = nil
    @ps = nil
    @output_dir = nil
    if @run
      @step = @run.step
      @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? JSON.parse(@step.attrs_json) : {}
      @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step.id).first
      @h_nber_runs = JSON.parse(@ps.nber_runs_json)
      step_dir = @project_dir + @step.name
      @output_dir = (@step.multiple_runs == true) ? (step_dir + @run.id.to_s) : step_dir
    end

    @layout = JSON.parse(@step.show_view_json)
    @h_outputs = JSON.parse(@run.output_json)
    
    if @step.has_std_view == true
      
      @h_el = {}
      ## initialize
      #@layout.each do |e|
      #  e["horiz_elements"].each do |e2|
      #    @h_el[e2.id]={}
      #  end
      #end
      
      ## set values for standard cards
      @h_el = {
        "card-status" => {
          :card_header => 'Status',
          :card_body => ""
        },
        "card-params" => {
          :card_header => 'Parameters',
          :card_body => ""
        },
        "card-downloads" => {
          :card_header => 'Results',
          :card_body => ""
        }
        
      }
    else
      specific_function = "get_run_#{@step.name}()"
      begin
        eval(specific_function)
      rescue
        ## do nothing for the moment - later we could check if this is normal regarding to the parameters - but for the moment this is not mandatory to create a specific method for a step                                           
      end
    end

    render :partial => (@step.has_std_view == true) ? 'get_run' : (@step.name + "_view")

  end

  def get_step_metadata
   
    [:metadata_type, :store_run_id].each do |k|
      session[k][@project.id] = params[k].to_i if params[k]
    end
    
    @h_annot = {
      :project_id => @project.id, 
      :dim => session[:metadata_type][@project.id]
    }
    @h_annot[:store_run_id] = session[:store_run_id][@project.id] if session[:store_run_id][@project.id] != 0
    @annots = Annot.where(@h_annot).all
    @log5 = @annots
    @h_data_types = {}
    DataType.all.map{|dt| @h_data_types[dt.id]=dt}

    ## get dashboard cards info for each valid step                                  
    @h_dashboard_card={}
    Step.all.each do |step|    
      @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    end

    @annot_runs = Run.where(:id => @annots.map{|a| a.run_id}.uniq).all

    # get outputs                                                                                                                                                                              
    @h_outputs = {}    
    #  @h_parents = {}
    @annot_runs.each do |r|                                                                                                                                                                  
      @h_outputs[r.id] = JSON.parse(r.output_json)  
      #    @h_run_parents[r.id] = JSON.parse(r.run_parents_json)
    end 
    
    ### look for runs corresponding to the file where is stored each metadata
    @h_store_runs={}
    Run.where(:id => @annots.map{|a| a.store_run_id}.uniq).all.each do |run|
      @h_store_runs[run.id] =run
    end
    
    ### add new metadata button
    @header_btns = "<button class='btn btn-sm btn-primary add_metadata_btn'><i class='fa fa-plus'/> Add metadata</span>"

  end

  def add_metadata
    h = {:upload_type => 2, :project_key => @project.key, :user_id => (current_user) ? current_user.id : 1}
    @fu_inputs = Fu.where(h).all
    
    if @fu_inputs.count > 0
      @fu_inputs.to_a.each do |fu_input|
        if fu_input.upload_file_name
          file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu_input.id.to_s + fu_input.upload_file_name
          File.delete file_path if File.exist?(file_path)
        end
        fu_input.destroy
      end
    end
    
    h[:status] = 'new'
    @fu_input = Fu.new(h)
    @fu_input.save!

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    parsing_dir = project_dir + "parsing"
    loom_file = parsing_dir + 'output.loom'
#    upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + @fu.id.to_s
#    filepath = upload_dir + @fu.upload_file_name

    @h_json = {}

    cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_file} -light -meta col_attrs/CellID"
    tmp_json = `#{cmd}`.gsub(/\n/, '')
    if tmp_json
      @h_json[:cells] = JSON.parse(tmp_json)['values'].first(10)
    end

    cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_file} -light -meta row_attrs/Gene"
    tmp_json = `#{cmd}`.gsub(/\n/, '')
    if tmp_json
      @h_json[:genes] = JSON.parse(tmp_json)['values'].first(10)
    end
    
    render :partial => 'add_metadata'
  end

  def get_step_summary
    @h_project_steps = {}
    ProjectStep.where(:project_id => @project.id).all.select{|ps| ps.status_id}.each do |ps|
      @h_project_steps[ps.step_id]=ps
    end
    @list_steps =  @h_project_steps.keys.map{|step_id| @h_steps[step_id]}.sort{|a, b| a.rank <=> b.rank}
    @list_cards = []
   
    @list_steps.each do |step|
      ps = @h_project_steps[step.id]
      card_text = ""
      if step.multiple_runs == false 
        run = Run.where(:project_id => @project.id, :step_id => step.id).first
        if run and admin?
          card_text += "##{run.id} "
        end
        card_text += display_status(@h_statuses[ps.status_id])
      else
        h_nber_runs = JSON.parse(ps.nber_runs_json)
        card_text = h_nber_runs.keys.select{|sid| @h_statuses[sid.to_i]}.map{|sid| display_status_runs(@h_statuses[sid.to_i], h_nber_runs[sid])}.join(" ")
      end
      
      h_card = {
        :card_id => "summary_step_card-#{step.id}",
        :card_class => "summary_step_card pointer",
        :body => "<h5 class='card-title'>#{step.label}</h5><p class='card-text'>#{card_text}</p>",
        :footer => "<small class='text-muted'>Last updated #{display_elapsed_time(ps.updated_at)}</small>"
      }
      @list_cards.push(h_card)
    end
  end

  def get_std_method_details(runs)
 
    h_std_method_attrs = {}
    std_method_ids = runs.map{|run| run.std_method_id}.uniq
    std_method_ids.each do |std_method_id|
      std_method = @h_std_methods[std_method_id]
      if std_method
        h_res = Basic.get_std_method_attrs(std_method, @h_steps[std_method.step_id])
        h_std_method_attrs[std_method_id] = h_res[:h_attrs]
      end
    end

    return h_std_method_attrs
  end

  def create_run_cards runs

    ## get dashboard_cards
    @h_dashboard_card={}
    step_ids = runs.map{|r| r.step_id}.uniq
    step_ids.map{|sid| @h_steps[sid]}.each do |step|
      @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    end      

    ## get std_method details
    h_std_method_attrs = get_std_method_details(runs)

    list_cards = []
    runs.each do |run|
      #    if !step_dir
      step_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + @h_steps[run.step_id].name
      output_dir = (@h_steps[run.step_id].multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      #    end
      h_attrs = (run.attrs_json) ? JSON.parse(run.attrs_json) : {}
      output_json_file = output_dir + "output.json"
      output_logfile = output_dir + "output.log"

      h_res = (File.exist? output_json_file) ? JSON.parse(File.read(output_json_file)) : {}
      h_outputs = (run.output_json.match(/^\{/)) ?  JSON.parse(run.output_json) : {}
      
      top_right = (action_name == 'get_step') ? "<div id='destroy-run_#{run.id}' class='btn_destroy-run'><i class='fa fa-times-circle'></i></div>" : ""
      
      h_files = {}
      if @h_dashboard_card[run.step_id]["output_files"]
        @h_dashboard_card[run.step_id]["output_files"].select{|e| h_outputs[e["key"]] and ((admin? or e["admin"] == true ) or !e["admin"])}.each do |e|
          k = e["key"]
          h_outputs[k].keys.each do |output_key| 
            t = output_key.split(":")
            h_files[t[0]] ||= {
              :h_output => h_outputs[k][output_key],
              :datasets => []
            }  
            h_files[t[0]][:datasets].push({:name => t[1], :dataset_size => h_outputs[k][output_key]['dataset_size']}) if t.size > 1 
#            display_download_btn(run, h_outputs[k][output_key])}}.flatten.join(" ")
          end
        end
      end
      
      h_card = {
        :card_id => "run_card_#{run.id}",
        :card_class => "run_card",
        :body => ["<div class='top-right-buttons'>#{top_right}</div><p class='card-title'>#{display_status_short @h_statuses[run.status_id]} 
<span id='show_run_#{run.id}' class='show_link pointer'><b>##{run.num}</b> #{(step = @h_steps[run.step_id] and step.multiple_runs == false) ? step.label : ((std_method = @h_std_methods[run.std_method_id]) ? ((!params[:step_id]) ? (step.label + " ") : "") + std_method.label : 'NA')}</span></p>",
                  #                  run.lineage_run_ids, 
                  #            h_attrs.to_json +                                                                                                                                                    
                  display_run_attrs(run, h_attrs, h_std_method_attrs),
                  ((run.status_id == 3 and @h_dashboard_card[run.step_id]["output_values"]) ? ("<p class='card-text'>" + @h_dashboard_card[run.step_id]["output_values"].map{|e| "<span class='badge badge-info'>#{e["label"]}:#{(h_res[e["key"]]) ? h_res[e["key"]] : 'NA'}</span>"}.join(" ") + "</p>") : ''),
                  # (h_files.keys.size > 0) ? ("<p class='card-text'>" +  + "</p>") : ""),
                  #   run.duration.to_json +                                                                                                                                                                 
                  #   run.output_json +                                                                                                                                                                      
                  #((@h_dashboard_card[run.step_id]["output_files"]) ? ("<p class='card-text'>" +  @h_dashboard_card[run.step_id]["output_files"].select{|e| h_outputs[e["key"]] and ((admin? or e["admin"] == true ) or !e["admin"])}.map{|e| k = e["key"]; h_outputs[k].keys.map{|k2| display_download_btn(run, h_outputs[k][k2])}}.flatten.join(" ") + "</p>") : ""),
                  ((h_files.keys.size > 0) ? ("<p class='card-text'>" + h_files.keys.map{|k| display_download_btn(run, h_files[k])}.join(" ") + "</p>") : ""),
                  #((run.status_id == 3 and h_res['warnings']) ? h_res['warnings'].map{|w| ("<p class='text-warning text-truncate' title='#{w['name'] || 'NA'} #{w['description'] || 'NA'}'>" + w['name'] + "</p>")}.join(" ") : ''),
                  ((run.status_id == 3 and h_res['warnings']) ? h_res['warnings'].map{|e| "<p class='text-warning text-truncate' title='#{e['name']}. #{e['description']}'>#{e['name']}</p>"}.join(" ") : ''),
                  ((run.status_id == 4) ? ("<p class='card-text'>" + ((h_res['displayed_error']) ? h_res['displayed_error'].map{|e| "<p class='text-danger text-truncate' title='#{e}'>#{e}</p>"}.join(" ") : '')) : "" )#,
                #  ((admin?) ? "<button id='run_#{run.id}_#{h_outputs[k][f]['onum']}' type='button' class='btn btn-sm btn-outline-secondary download_file_btn'>Log file</button>" : "")
                 ].join(""),
        
        :footer => "<small class='text-muted'>" +
        ((admin?) ? "##{run.id}, "  : "") +
        ["<span class='nowrap'>#{display_date_short(run.created_at)}</span><span id='created_time_#{run.id}' class='hidden'>#{run.submitted_at.strftime "%Y-%m-%d %H:%M:%S"}</span><span id='start_time_#{run.id}' class='hidden'>#{(run.start_time) ? run.start_time.strftime("%Y-%m-%d %H:%M:%S") : ""}</span>",
         ((run.waiting_duration) ? "<span class='nowrap'>Wait #{duration(run.waiting_duration.to_i)}</span>" : ((run.status_id == 1) ? "<span id='ongoing_wait_#{run.id}' class='nowrap'>Wait #{duration((Time.now-run.submitted_at).to_i)}</span>" : nil)), 
         ((run.duration) ? "<span class='nowrap'>Run #{duration(run.duration.to_i)}</span>" : ((run.status_id == 2) ? "<span id='ongoing_run_#{run.id}' class='nowrap'>Run #{duration((run.start_time) ? (Time.now-run.start_time).to_i : 0)}</span>" : nil)),
         ((h_res['time_idle']) ? "<span class='nowrap'>Idle #{duration(h_res['time_idle'].to_i)}</span>" : nil),  
         ((run.max_ram) ? "<span class='nowrap'>Max. RAM #{display_mem(run.max_ram*1000)}</span>" : nil)].compact.join(", ") + #.join(", ") 
         "</small>" #+
#        " lineage: #{run.lineage_run_ids}"
        #"<button type='button' class='btn btn-primary'>Details</button>"                                                                                                                           
      }
      list_cards.push(h_card)
    end
    return list_cards
  end

  def lineage_filter
 
    @h_all_lineage_run_ids = {}
    @h_all_runs = {}
    @current_run_ids = []
    Run.joins("join steps on (runs.step_id = steps.id)").where(["project_id = ?", @project.id]).order("id desc").all.each do |run|
      @h_all_runs[run.id] = run
     # if active_run.status_id == 3
        @h_all_lineage_run_ids[run.id] = (run.lineage_run_ids) ? run.lineage_run_ids.split(",").map{|e| e.to_i} : []
     # end
      @current_run_ids.push(run.id) if action_name == 'form_select_input_data' or run.step_id == @step.id
    end

    @log = ''

    if params[:activated_filter]
      @log += 'bla'
      session[:activated_filter][@project.id] = (params[:activated_filter] == '1') ? true : false
    end

    if params[:add_lineage_run_ids]
      params[:add_lineage_run_ids].split(",").map{|e| e.to_i}.each do |run_id|
        session[:filter_lineage_run_ids][@project.id].push(run_id) if !session[:filter_lineage_run_ids][@project.id].include?(run_id)
      end
    elsif params[:del_lineage_run_ids]
      params[:del_lineage_run_ids].split(",").map{|e| e.to_i}.each do |run_id|
        #        session[:filter_lineage_run_ids].delete(run_id) if session[:filter_lineage_run_ids].include?(run_id)                           
        @log+= "TREAT_session #{session[:filter_lineage_run_ids].to_json}"                                                
        to_delete = {}
        session[:filter_lineage_run_ids][@project.id].each do |run_id2|
          if (@h_all_lineage_run_ids[run_id2] and @h_all_lineage_run_ids[run_id2].include? run_id) or run_id == run_id2
            to_delete[run_id2] = 1
          end
        end
        session[:filter_lineage_run_ids][@project.id].reject!{|e| to_delete[e]} ## delete run_ids
      end
    end

    ## define filters based on the session variable                                                                                                                                                            
    @filter_lineage_run_ids = session[:filter_lineage_run_ids][@project.id].dup

    ## compute implicit filters                                                                                                                                                                                
    @implicit_filter_lineage_run_ids = []
    @filter_lineage_run_ids.each do |run_id|
      @log +="HERE#{run_id} "
      tmp_lineage = @h_all_lineage_run_ids[run_id].dup
      if tmp_lineage
        tmp_lineage.shift
        @implicit_filter_lineage_run_ids |= tmp_lineage
      end
    end
    @log +="Implicit filters: " + @implicit_filter_lineage_run_ids.to_json


    ## add implicit filters to session                 
    #    @implicit_filter_lineage_run_ids.each do |run_id|                   
    #      session[:filter_lineage_run_ids].push(run_id) if !session[:filter_lineage_run_ids].include? run_id                            
    #    end                                                                                                                                                                                                      
    ##filter out from filters run_ids that do not exist anymore (in this step context)                                                                                                                                                                                                                                                                                                          
    @filter_lineage_run_ids.reject!{|run_id| tmp_run = @h_all_runs[run_id]; !tmp_run or @h_steps[tmp_run.step_id].rank >= @step.rank}

    ## filter out from implicit_filters run_ids that do not exist anymore                                                                                                                                      
    @implicit_filter_lineage_run_ids.reject!{|run_id| tmp_run = @h_all_runs[run_id]; !tmp_run or @h_steps[tmp_run.step_id].rank >= @step.rank}

    ## compute children of the latest nodes                                                                                                                                                                    
    @list_filter_run_ids = @implicit_filter_lineage_run_ids | @filter_lineage_run_ids

    ## deactivated the filter if no more filter applicatble (except if click on filter button)                                                                                                                 
    if session[:filter_lineage_run_ids][@project.id].size == 0 and params[:activated_filter] != '1'
      session[:activated_filter][@project.id] = false
    end

    ## define the list of runs after applying filters                                                                                                                                                          
    @current_filtered_run_ids = []
    if session[:activated_filter][@project.id] == true and @list_filter_run_ids.size > 0
      @max = 0
      @current_run_ids.map{|run_id| tmp = @h_all_lineage_run_ids[run_id] & @list_filter_run_ids; @max = tmp.size if tmp and @max < tmp.size }
      @current_filtered_run_ids = @current_run_ids.select{|run_id| tmp = @h_all_lineage_run_ids[run_id] & @list_filter_run_ids; tmp and @log+="#{@max} #{tmp.size} >= [#{@h_all_lineage_run_ids[run_id].size}, #{@list_filter_run_ids.size}].min" and  tmp.size == @max} # [@h_all_lineage_run_ids[run_id].size, @list_filter_run_ids.size].min}
      
      #      if params[:activated_filter] != '1' and @current_filtered_run_ids == @current_run_ids
#        @log +='blo'
        #        session[:activated_filter] = false                        
        #        @filter_lineage_run_ids = [] 
        #        @implicit_filter_lineage_run_ids = []
#      end

   else
#      @log +='bliiiii'
      @current_filtered_run_ids = @current_run_ids
#      @log += @current_filtered_run_ids.to_json
    end
    
    #    if @current_filtered_run_ids == @current_run_ids and @filter_lineage_run_ids.size ==0 and @implicit_filter_lineage_run_ids.size == 0    
    #      @log +='blo'                      
    #      session[:activated_filter] = false      
    #    end      
    
    #   else  
    #      @current_filtered_run_ids = @current_run_ids       
    #   end                   
    
    ## define the uniq list of runs in the lineage of filtered runs                                                                                                                                            
    @all_lineage_run_ids=[]
    #    @current_run_ids.select{|run_id| @h_all_lineage_run_ids[run_id]}.each do |run_id|                                                                                                                     
    @current_run_ids.each do |run_id|
      tmp_lineage =  @h_all_lineage_run_ids[run_id].dup
      if tmp_lineage
        tmp_lineage.shift ## remove parsing              
        # tmp_lineage_run_ids.each do |run_id|          
        #   @h_union_lineage_run_ids[run_id.to_i] = 1          
        # end                                 
        @all_lineage_run_ids |= tmp_lineage
      end
    end
    
    ## check run_ids that are not in session                                                                                                                                                                   
    @h_lineage_run_ids_by_step_id = {}

    #    if  @filter_lineage_run_ids.size != 0         
    @all_lineage_run_ids.each do |run_id|
      #  if !@local_filter_lineage_run_ids.include? run_id and !((@h_all_lineage_run_ids[run_id] & @local_filter_lineage_run_ids).size > 0)       
      #  @local_filter_lineage_run_ids.push(run_id)                 
      #  session[:filter_lineage_run_ids].push(run_id)                                                                                                                                                         
      if !@filter_lineage_run_ids.include? run_id and !@implicit_filter_lineage_run_ids.include? run_id
        @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id] ||= []
        @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id].push run_id
      end
    end
    #    else                    
    #      @all_lineage_run_ids.each do |run_id|                
    #        @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id] ||= []    
    #        @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id].push run_id                     
    #      end                                  
    #    end         
                                                                                                       
    ## compute children of the latest nodes                                                                                                                                                                    
    @list_filter_run_ids = @implicit_filter_lineage_run_ids | @filter_lineage_run_ids

    ## sort filters
    @list_filter_run_ids.sort!{|a, b| a2 = @h_all_runs[a]; b2 = @h_all_runs[b]; as = a2.step_id; bs = b2.step_id;  [@h_steps[as].rank, a2.num] <=> [@h_steps[bs].rank, b2.num] }

    @h_children_run_ids={}
    @h_lineage_run_ids_by_step_id.each_key do |step_id|
      @h_lineage_run_ids_by_step_id[step_id].each do |run_id|
        if @list_filter_run_ids.include? @h_all_lineage_run_ids[run_id].last
          @h_children_run_ids[run_id]=1
        end
      end
    end

    ## check if the filter should be disabled                                                                                                                                         
    @disable_filter = true
    #  @h_lineage_run_ids_by_step_id.each_key do |step_id| 
    #   if @h_lineage_run_ids_by_step_id[step_id].size > 0             
    #     @disable_filter = false          
    #     break     
    #   end 
    #  end 
                                                                                                                                                                                                   
    @current_run_ids.each do |run_id|
      if @h_all_lineage_run_ids[run_id] and @h_all_lineage_run_ids[run_id].size > 1
        @disable_filter = false
      end
    end
    
    ### set flag to temporarily not display the filter selection box
    @flag_nothing_to_filter = (@current_filtered_run_ids == @current_run_ids and @filter_lineage_run_ids.size ==0 and @implicit_filter_lineage_run_ids.size == 0) or ( @list_filter_run_ids.size == 0 and params[:activated_filter] != '1')


    #    @lineage_runs = Run.where(:id =>session[:filter_lineage_run_ids]).all 
    #@lineage_runs = session[:filter_lineage_run_ids].     
    
  end

  def check_session_params runs, h_attr
    ## evaluate if there are runs where all params
    @log3 = ''
    @filter_runs = runs.select{|r| h_attr[r.id]["nber_dims"] == session[:dr_params][@project.id][:nber_dims] and r.std_method_id == session[:dr_params][@project.id][:std_method_id]}
   
    if @filter_runs.size == 0
      new_ref = runs.first
      session[:dr_params][@project.id][:nber_dims] = @h_attrs_by_run_id[new_ref.id]["nber_dims"]
      session[:dr_params][@project.id][:std_method_id] = new_ref.std_method_id
    end
    
  end


  def get_step_dim_reduction
 
    ## set session for std_method_id and nber_dims
    session[:dr_params][@project.id][:nber_dims]||=2
    [:std_method_id, :nber_dims].select{|e| params[e]}.each do |e|
      session[:dr_params][@project.id][e]= params[e].to_i
    end

    ## filter only successful runs
    @successful_runs = @runs.select{|r| r.status_id == 3}

    ## get attrs for all runs
    @h_attrs_by_run_id = {}
    @runs.each do |r|
      @h_attrs_by_run_id[r.id]=JSON.parse(r.attrs_json)
    end
   
#    @log4 = @runs.map{|r| [r.id, r.attrs_json]}.to_json
 
    ## check session parameters and change them if not valid anymore
    check_session_params(@runs, @h_attrs_by_run_id)

    ## filter runs by attr nber_dims
    @successful_runs = @successful_runs.select{|r| @h_attrs_by_run_id[r.id]['nber_dims'] == session[:dr_params][@project.id][:nber_dims]}
    
    @log = ''
    @finished_runs = 
    ## define default run_id
    if @successful_runs.size > 0
    
      ## define default std_method_id in session                                                                                                                                    
      session[:dr_params][@project.id][:std_method_id]||=@successful_runs.first.std_method_id
      
      ## filter runs by std_method_id            
      @successful_runs = @successful_runs.select{|r| session[:dr_params][@project.id][:std_method_id] == r.std_method_id}
      
      if @successful_runs.size > 0
        
        if !params[:run_id]
          
          @default_run_id = @runs.first.id
        elsif params[:run_id] 
          run = Run.where(:id => params[:run_id]).first
        
          #       @log += run.attrs_json
          if (run and m = run.attrs_json.match(/nber_dims\"\:(\d+)/))
            #          @log += m[1]
            if m[1] != params[:nber_dims] and 
                run2 = Run.where(:project_id => @project.id, :step_id => 4, :attrs_json => run.attrs_json.gsub(/nber_dims\"\:(\d+)/, "nber_dims\":#{session[:dr_params][@project.id][:nber_dims]}")).first
              @default_run_id = run2.id
            else
              @default_run_id = run.id
            end
          end
        end
      end
    end
    ## get std_method details           
    @h_std_method_attrs = get_std_method_details(@runs)
    @default_std_method_id = params[:std_method_id].to_i || @h_std_method_attrs.keys.first
   
    ## borrow dashboard_card info
    @h_dashboard_card={}
    step_ids = @runs.map{|r| r.step_id}.uniq
    step_ids.map{|sid| @h_steps[sid]}.each do |step|
      @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    end
    
  end
  
  def get_step

    ### redefine the current project (if other windows will change them to this project)
    session[:current_project]=@project.key
  @lod = 'e'
    get_base_data()
    @h_std_methods = {}
    StdMethod.all.map{|s| @h_std_methods[s.id] = s}
    #    @h_steps={}
    #   Step.all.map{|s| @h_steps[s.id]=s}
    
    #    @h_pdr={}
    #    ProjectDimReduction.where(:project_id => @project.id).all.map{|pdr| @h_pdr[pdr.dim_reduction_id]=pdr}

    session[:active_step] = params[:active_step].to_i if params[:active_step]
    @step_id = params[:step_id].to_i || session[:active_step]
    @step = @h_steps[@step_id]

    @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step_id).first
    @h_nber_runs = JSON.parse(@ps.nber_runs_json)

    if @step.multiple_runs == true
      lineage_filter()
   # else
   #   @current_filtered_run_ids = ActiveRun.
    end

    @results = {}
    @all_results = {}
    @results_parsing={}
    @h_batches={}
    @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? JSON.parse(@step.attrs_json) : {}

    if params[:dashboard]
      session[:current_dashboard][@project.id][@step.id] = params[:dashboard]
    elsif @h_attrs["dashboards"] and default_dashboard = @h_attrs["dashboards"].first
      session[:current_dashboard][@project.id][@step.id] ||= default_dashboard['name'] 
    elsif @step.has_std_dashboard
       session[:current_dashboard][@project.id][@step.id] ||= 'std_runs'
    else
      session[:current_dashboard][@project.id][@step.id] ||= @step.name
    end
    

    #jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => [1, 2, 3, 4]).all.to_a.compact
    #jobs.sort!{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')} if jobs.size > 0
    #last_job = jobs.last
    #@last_update = @project.status_id.to_s + ","
    #@last_update += [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job
    @last_update = get_last_update_status()
   # session[:last_update_active_step]= @last_update
    session[:active_dr_id] ||= 1
    session[:active_viz_type] ||= 'dr'

    step_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + @step.name

    if readable? @project #(current_user and current_user.id == @project.user_id) or admin? or @project.public == true or @project.sandbox == true
  #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + @h_steps[session[:active_step]].label.downcase
  #    filename = tmp_dir + "output.json"
  #    logger.debug("FILE: " + filename.to_s)
  #    @h_statuses = {}
  #    Status.all.map{|s| @h_statuses[s.id] = s}
  
#      @runs = ActiveRun.where(:project_id => @project.id, :step_id => @step.id).order("id desc").all
   #   @runs = @current_filtered_run_ids.map{|run_id| @h_all_runs[run_id]}  #  (@current_filtered_run_ids.size > 0) ? @current_filtered_run_ids.map{|run_id| @h_all_runs[run_id]} : @current_run_ids.map{|run_id| @h_all_runs[run_id]}
     # lineage_run_ids = @runs.map{|e| e.lineage_run_ids.split(",")}.flatten.uniq
     # lineage_runs = ActiveRun.where(:project_id => @project.id, :id => lineage_run_ids).all
     # @h_lineage_runs = {}
     # lineage_runs.each do |lineage_run|
     #   @h_lineage_runs[@h_steps[lineage_run.step_id].label]||=[]
     #   @h_lineage_runs[@h_steps[lineage_run.step_id].label].push lineage_run
     # end
      
      @list_cards = []
      
      if @step.multiple_runs == true 
        @runs = @current_filtered_run_ids.map{|run_id| @h_all_runs[run_id]} 
        
        ## compute the uniq list of methods for successful runs
        @h_std_method_ids = {}
        @runs.select{|r| r.status_id == 3}.map{|r| @h_std_method_ids[r.std_method_id] = 1}
        current_dashboard = session[:current_dashboard][@project.id][@step.id]
        if @runs.size > 0 and (!@h_attrs["dashboards"] or current_dashboard=='std_runs')
          
          #       h_dashboard_card = JSON.parse(@step.dashboard_card_json)
          @list_cards = create_run_cards(@runs)
        end
#          <div class='card'>
#<div class='card-body'>
#<div class='top-right-buttons'>
#  <div id='destroy-run_<%= run.id %>' class='btn_destroy-run'><i class='fa fa-times-circle'></i></div>
#</div>
#<%# run.id %>
#<p class='card-title'><b><%= raw display_status_short  @h_statuses[run.status_id] %> #<%= run.num %></b> <%= @h_std_methods[run.std_method_id].label %></p>
#<% h_attrs = JSON.parse(run.attrs_json) %>
#<p class='card-text'><%= raw h_attrs.keys.map{|k| v = h_attrs[k]; "<span class='badge badge-info'>#{k}:#{(v.is_a? Hash and v['run_id'] and tmp_run = Run.find(v['run_id']) and tmp_step = @h_steps[tmp#_\
#run.step_id]) ? (tmp_step.name + ((tmp_step.multiple_runs == true) ? (" #" + tmp_run.num.to_s) : '')) : v }</span>"}.join(" ") %></p>
#<p class='card-text'></p>
#</div>
#</div>
#
#<% end %>


      end
      @error = ''
      specific_function = "get_step_#{@step.name}()"
      begin
        eval(specific_function)
      rescue Exception => e
        ## do nothing for the moment - later we could check if this is normal regarding to the parameters - but for the moment this is not mandatory to create a specific method for a step
        @error = e.message #e.backtrace
      end

      get_results()
      get_batch_file_groups()      
      #      if  session[:active_step] > 1
      #        tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + "parsing"
      #        filename = tmp_dir + "output.json"
      #        results_json = File.open(filename, 'r').read
      #        @results_parsing = JSON.parse(results_json)
      #      end
      
    end
    
    respond_to do |format|
      format.html { 
#        session[:to_update] = 0
        render :partial => params[:partial] || "get_step"
#        session[:to_update] = 0
#        active_step_name = @h_steps[session[:active_step]].name
#        if @project.step_id < session[:active_step] and !(@project.step_id ==3 and @project.status_id == 3) and session[:active_step] < 5
#          render :partial => "form_" + active_step_name
#          session[:to_update] = 0
#        else
#          render :partial => active_step_name
#          session[:to_update] = 0
#        end
        #   format.json { render json: @project }
      }
    end
  end

  def get_step_header

    get_base_data()
    @h_std_methods = {}
    StdMethod.all.map{|s| @h_std_methods[s.id] = s}
    @step_id = params[:step_id].to_i || session[:active_step]
    @step = @h_steps[@step_id]
    @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? JSON.parse(@step.attrs_json) : {}
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step_id).first
    @h_nber_runs = JSON.parse(@ps.nber_runs_json)
    
    render :partial => "step_header_container"
    
  end

  def get_attributes
    @log = ''
    session[:input_data_attrs][@project.id]||={}
    session[:input_data_attrs][@project.id][params[:step_id]]||={}
    
    #    h_obj = {
    #      'filter_method' => FilterMethod,
    #      'norm' => Norm,
    #      'cluster_method' => ClusterMethod,
    #      'diff_expr_method' => DiffExprMethod
    #    }
    
    #    h_step = {
    #      'filter_method' => 2,
    #      'norm' => 3,
    #      'cluster_method' => 5,
    #      'diff_expr_method' => 6
    #    }
    get_base_data()
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @step = @h_steps[params[:step_id].to_i]
    @std_method = StdMethod.find(params[:obj_id])
    h_res = get_attr(@step, @std_method)
    @h_attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]
    
    ## check attributes with valid_types

    @h_unavailable_inputs={}
    runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
    h_res[:attrs].each_key do |attr_name|
      if  h_res[:attrs][attr_name]['valid_types']
        valid_types = h_res[:attrs][attr_name]['valid_types']
        source_steps = h_res[:attrs][attr_name]['source_steps']
        h_constraints =  h_res[:attrs][attr_name]['constraints']
        source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
        tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
        h_res2 = check_valid_types(@step, tmp_runs, valid_types, source_steps, h_constraints)
        if h_res2[:h_runs].keys.size == 0
          @h_unavailable_inputs[attr_name] = h_res2                                                                                                                           
        end
      end
    end

    ### filter out datasets already selected and that are not available
    session[:input_data_attrs][@project.id][params[:step_id]].each_key do |attr_name|
      list_datasets_to_remove = []
      session[:input_data_attrs][@project.id][params[:step_id]][attr_name].each_index do |i|
        h = session[:input_data_attrs][@project.id][params[:step_id]][attr_name][i]
        if u = @h_unavailable_inputs[attr_name]  and u[:h_runs] and u[:h_runs][h['run_id']]
          list_datasets_to_remove.push i
        end
      end
      list_datasets_to_remove.each do |i|
        session[:input_data_attrs][@project.id][params[:step_id]][attr_name].slice(i)
      end
    end
    

#    @h_attrs = {}
#    run = StdRun.where(:project_id => @project.id, :std_method_id => @obj_inst.id)

#    if params[:step_name] == 'gene_filtering'
#      @h_attrs = JSON.parse(@project.filter_method_attrs_json || "{}")
#    elsif params[:step_name] == 'normalization'
#      @h_attrs = JSON.parse(@project.norm_attrs_json || "{}")
#    elsif params[:step_name] == 'clustering'
#      @h_attrs = JSON.parse((c = Cluster.where(:project_id => @project.id, :cluster_method_id => @obj_inst.id).order("id desc").first && c && c.attrs_json) || "{}")
#    elsif params[:step_name] == 'diff_expr'
#      @h_attrs = JSON.parse((de = DiffExpr.where(:project_id => @project.id, :diff_expr_method_id => @obj_inst.id).order("id desc").first && de && de.attrs_json) || "{}")
#    end

    @warning = @std_method.warning if @std_method.respond_to?(:warning)
    
    @batch_file_exists = 1 if File.exist?(tmp_dir + "parsing" + "group.tab") 
    @ercc_file_exists = 1 if File.exist?(tmp_dir + "parsing" + "ercc.tab")

    render :partial => 'attributes' #, locals: {h_attrs: @h_attrs} 
    
  end

  def set_input_data

    @log = ''

    ## get attributes                                                                                                                                                                                           
    get_base_data()
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @step = @h_steps[params[:step_id].to_i]
    @std_method = StdMethod.find(params[:obj_id])
    h_res = get_attr(@step, @std_method)
    @h_attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]
    
    ## define input data
    session[:input_data_attrs][@project.id]||={}
    session[:input_data_attrs][@project.id][params[:step_id]] ||= {}

    if session[:input_data_attrs][@project.id][params[:step_id]][params[:attr_name]] != params[:list_attrs]      
      session[:input_data_attrs][@project.id][params[:step_id]][params[:attr_name]] = []
      @h_attrs.keys.select{|attr_name| c = @h_attrs[attr_name]['constraints'] and c['in_lineage'] and c['in_lineage'].include?(params[:attr_name])}.each do |attr_name|
        session[:input_data_attrs][@project.id][params[:step_id]][attr_name]=[]
      end
      params[:list_attrs].split(",").each do |e|
        e2 = e.split(":")
        session[:input_data_attrs][@project.id][params[:step_id]][params[:attr_name]].push({:run_id => e2[0], :output_attr_name => e2[1], :output_filename => e2[2], :output_dataset => (e2.size > 3) ? e2[3] : nil })
      end
    end

    
    @warning = @obj_inst.warning if @obj_inst.respond_to?(:warning)
    
    @batch_file_exists = 1 if File.exist?(tmp_dir + "parsing" + "group.tab")
    @ercc_file_exists = 1 if File.exist?(tmp_dir + "parsing" + "ercc.tab")
    
    ## find the layout context
    horiz_element = false
    
    @attr_layout.each do |tmp_vertical_el|
      tmp_vertical_el["horiz_elements"].each do |tmp_horiz_element|
        if  tmp_horiz_element['attr_list']
          tmp_horiz_element['attr_list'].select{|k| attr = @h_attrs[k]; attr and attr['widget'] and !attr['obsolete']}.each do |attr_name| 
            if attr_name == params[:attr_name]
              horiz_element = tmp_horiz_element
              break 
            end
          end
        end
      end
    end

    ## set dependent attributes
    @dependent_attributes=[]    
     @h_attrs.each_key do |attr_name|
      if  c = @h_attrs[attr_name]['constraints'] and c['in_lineage'] and c['in_lineage'].include?(params[:attr_name])
        @dependent_attributes.push(attr_name)
      end
    end

    ## render the attribute
    params[:validate_form] = 1
    render :partial => 'attribute', :locals => {:attr_name => params[:attr_name], :horiz_element => horiz_element}
    ## render the form

    ## check attributes with valid_types                                                                                                                                                                        
   # @h_unavailable_inputs={}
   # runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
   # h_res[:attrs].each_key do |attr_name|
   #   if  h_res[:attrs][attr_name]['valid_types']
   #     valid_types = h_res[:attrs][attr_name]['valid_types']
   #     source_steps = h_res[:attrs][attr_name]['source_steps']
   #     h_constraints =  h_res[:attrs][attr_name]['constraints']
   #     source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
   #     tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
   #     h_res2 = check_valid_types(@step, tmp_runs, valid_types, source_steps, h_constraints)
   #     if h_res2[:h_runs].keys.size == 0
   #       @h_unavailable_inputs[attr_name] = h_res2
   #     end
   #   end
   # end

#    render :partial => "attributes"

  end

  def get_file_old
 
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    
    ### get gene_file
    if File.exists?(tmp_dir + "parsing" + 'gene_names.json')
      list_gene_names = JSON.parse(File.read(tmp_dir + "parsing" + 'gene_names.json'))
    end
    ### get file    
    filename = params[:filename] || "output.tab"
    data = ""
    tmp_data = []
    if filename == "output.tab"
      File.open(tmp_dir + params[:step] + filename, 'r') do |f|
        if list_gene_names
          tmp_data.push(f.gets) ## get header 
          i = 0
          while l = f.gets do
            t = l.split("\t")
            j = t.shift        
            e = [[0,1,2].map{|j| list_gene_names[i][j]}.select{|e| e and e!=''}.join("|")]
            tmp_data.push((e + t).join("\t")) 
            i+=1
          end
          data = tmp_data.join("")
        else
          data = f.readlines.join("")
        end
      end  
    else
      data = File.read(tmp_dir + params[:step] + filename)
    end
    send_data data, type: params[:content_type] || 'text', disposition: (!params[:display]) ? ("attachment; filename=" + params[:step] + "_" + filename) : ''
  end
  
  def get_file

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + @project.key
    run_id = (params[:run_id]) ? params[:run_id] : nil #((params[:filename] and m = params[:filename].match(/^(\d+)\.\w{1,3}/)) ? m[1].to_i : nil)                                                                       
    step_name = params[:step]
    if run_id
      run =  Run.where(:id => run_id).first
      h_outputs = JSON.parse(run.output_json)
      h_file_by_id = {}
      h_outputs.each_key do |k|
        h_outputs[k].each_key do |k2|
          t = k2.split(":")
          relative_path = t[0]
          full_path = project_dir + relative_path 
          h_file_by_id[h_outputs[k][k2]['onum']]={:filename => h_outputs[k][k2]['filename'], :filepath => full_path}
        end
      end
      step_name = (step = run.step) ? step.name : nil
    end
    
    filepath = nil
    filename = nil
    if params[:onum]
      filename = h_file_by_id[params[:onum].to_i][:filename]
      filepath = h_file_by_id[params[:onum].to_i][:filepath]
    elsif params[:filename]
      filename = params[:filename]
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key] 
      tmp_dir += step_name if step_name
      tmp_dir += params[:run_id].to_s if params[:run_id]
      filepath = tmp_dir + filename
    end
    
    ext =  filename.split(".").last
    #    obj = c.constantize if params[:step] and c= params[:step].classify and ['GeneSet'].include?(c)
    #    obj = Run
    
    if readable?(@project) and (exportable? @project or ['png', 'pdf', 'jpeg', 'jpg'].include?(ext)) or (step_name == 'visualization' and filename.match(/trajectory/) and ext == 'json') or (step_name and run and exportable_item?(@project, run))
      
      send_file filepath.to_s, type: params[:content_type] || 'text', # type: 'application/octet-stream'
      x_sendfile: true, buffer_size: 512, disposition: (!params[:display]) ? ("attachment; filename=" + [@project.key, step_name,  run_id, filename].compact.join("_")) : ''
    else
      render :text => 'Not authorized to download this file'
    end
    
  end
  
  def upload_file
    
    if params[:key] #and current_user
      user = current_user || User.find(1)
      user = @project.user if @project

      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + user.id.to_s
      Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
      tmp_dir += (@project) ? @project.key : params[:key]
      Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
      
      filename = tmp_dir + (params[:type] + ".txt")     
      #Multipart.
      File.open(filename, 'w') do |f|         
        f.write(params[(params[:type] + "_file").intern].read.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8))
      end
      `dos2unix #{filename}`
      `mac2unix #{filename}`    
    end    
    #    render :text => params[(params[:type] + "_file").intern].original_filename
    render :text => '{}'
    # render :text => params.to_json
  end

  def get_projects
    
    [:limit, :public_limit, :free_text, :public_free_text].each do |e|
      session[:settings][e] = params[e] if params[e] 
    end
    settings = session[:settings]

  #  settings[:limit]=10
  #  settings[:public_limit]=10
    public_base_search = (settings[:public_free_text] and !settings[:public_free_text].empty?) ? Project.where("lower(name) ~ ?", settings[:public_free_text].downcase) : Project

    h = {:public => true}
    h[:user_id] = 1 if !current_user
    @h_counts={:public => 0, :private => 0}
    @h_counts[:public] =  public_base_search.where(h).count
    @public_projects = public_base_search.where(h).order("updated_at desc").limit(settings[:public_limit]).all.to_a
    
    base_search = (settings[:free_text] and !settings[:free_text].empty?) ? Project.joins("join users on (users.id = user_id)").where("lower(name) ~ ? or key ~ ? or users.email ~ ?", settings[:free_text].downcase, settings[:free_text].downcase, settings[:free_text].downcase) : Project

    shared_project_ids = []
    if current_user and !admin?
      shares = Share.where(:user_id => current_user.id).all
      shared_project_ids =  Share.where(:user_id => current_user.id).map{|e| e.project_id} if shares.size > 0
    end

    tmp_projects = (current_user) ? ((admin?) ? base_search : 
                                     base_search.where("user_id = ? or projects.id IN (?)", current_user.id, shared_project_ids)) : 
      #  base_search.where("user_id = ?", current_user.id)) :
      base_search.where(:user_id => 1, :sandbox => true, :key => session[:sandbox])
    
    tmp_projects = tmp_projects.order("updated_at desc")
    @h_counts[:private] = tmp_projects.count
    @projects = tmp_projects.limit(settings[:limit]).all.to_a

#    if current_user and !admin?
#      shares = Share.where(:user_id => current_user.id).all
#      @projects|= base_search.where({:id => Share.where(:user_id => current_user.id)}.map{|e| e.project_id}).all if shares.size > 0
#    end
  end

  # GET /projects
  # GET /projects.json
  def index
    get_projects()
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    @h_archive_statuses = {}
    ArchiveStatus.all.map{|s| @h_archive_statuses[s.id] = s}
    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id]=o}

     respond_to do |format|
      format.html { 
        if params[:nolayout]
          render :partial => 'index'
        else
          render :layout => 'welcome'
        end
      }
      format.json { render json: @projects }
    end
    
  end

  # GET /projects/1
  # GET /projects/1.json
  def show

    @error = ''
    if @project

      @version =@project.version
      @h_env = JSON.parse(@version.env_json)
      
      ### define the current project
      #if session[:current_project] != @project.key

      [:input_data_attrs, :filter_lineage_run_ids, :activated_filter, :current_dashboard, :dr_params, :metadata_type, :store_run_id].each do |k|
        session[k]||={}
      end

      session[:store_run_id][@project.id]=0
      session[:metadata_type][@project.id]=1
      session[:input_data_attrs][@project.id]||={}
      session[:filter_lineage_run_ids][@project.id]||=[]
      session[:activated_filter][@project.id]=false
      session[:current_dashboard][@project.id]={}
#      session[:global_dr_params][@project.id]||={:dot_opacity => 0.5, :dot_size => 3, :coloring_type => "1", :std_method_id => nil, :nber_dims => 2}
      session[:dr_params][@project.id]||={
        :dot_opacity => 0.5, :dot_size => 3, :coloring_type => "1", :std_method_id => nil, :nber_dims => 2, :cat_annot_id => nil,
        #   :row_i_1 => nil,
        #   :dataset_annot_id_1 => nil,
        #   :gene_selected_1 => '',
        #   :annot_id_1 => nil,
        #   :header_i_annot_id_1 => nil,
        #      :coloring_type => "1",
        # :data_type => "1",
        :occ_1 => {:data_type => "1"},
        :occ_2 => {:data_type => "1"},
        :occ_3 => {:data_type => "1"},
        :occ_4 => {:data_type => "1"}
        #        :gradients => [],
        #        :channels => [],
        #        :gene_pos => nil,
        #        :annot_id => nil
      }

      session[:dr_params][@project.id][:dot_opacity] ||= 0.5
      session[:dr_params][@project.id][:dot_size] ||= 3
      session[:dr_params][@project.id][:coloring_type]||= "1" if !["1", "2"].include?(session[:dr_params][@project.id][:coloring_type])

      session[:current_project]=@project.key
      #    session[:reload_step]=0
      
      if readable? @project
        
        ### have to ensure the project is in status unarchived
        if @project.archive_status_id != 1
          while [2, 4].include? @project.archive_status_id
            sleep 0.2
          end
          if @project.archive_status_id == 3
            @unarchive_cmd = "rails unarchive[#{@project.key}]"
            `#{@unarchive_cmd}`
            logger.debug(@unarchive_cmd)
          end
        end
        
        #      session[:viz_params]={
        #        'dim1' => 1,
        #        'dim2' => 2,
        #        'dim3' => 3,
        #        'color_by' => 'gene_text',
        #        'gene_text' => '',
        #        'dataset' => 'normalization',
        #        'cluster_id' => nil,
        #        'selection_id' => nil,
        #        'geneset_type' => 'all',
        #        'global_geneset' => (global_geneset = GeneSet.where(:user_id => 1, :project_id => nil, :organism_id => @project.organism_id).order("label").first && global_geneset && global_geneset.id) || nil,
        #        'custom_geneset' => (custom_geneset = GeneSet.where(:project_id => @project.id).order("label").first && custom_geneset && custom_geneset.id) || nil,
        #        'geneset_name' => ''
        #        #        'heatmap_input_type' => 'normalization'
        #      }
        session[:cart_display]=nil
        
        last_ps =  ProjectStep.where(:project_id => @project.id, :status_id => [1, 2, 3, 4]).order("updated_at desc").first
        last_step_id = (last_ps) ? last_ps.step_id : 1
        @last_update = get_last_update_status()
        session[:active_step]=last_step_id
        ### override active step if coming from update project form                                                                                                                     
        session[:active_step] = session[:override_active_step] if session[:override_active_step]
        @step_id = params[:step_id].to_i || session[:active_step]
        session.delete(:override_active_step)
        
        params[:active_step]=last_step_id
        session[:last_step_status_id]=@project.status_id
        params[:last_step_status_id]=@project.status_id
        session[:last_step_id]=last_step_id
        
        ### setup selections
        session[:selections]={}
        if readable?(@project)
          project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
          selection_dir = project_dir + 'selections'
          Dir.mkdir selection_dir if !File.exist?(selection_dir)
          @project.selections.each do |selection|
            file = selection.id.to_s + ".txt"
            File.open(selection_dir + file, 'r') do |f|
              session[:selections][selection.id]={:item_list => f.readlines.map{|e| e.chomp}.sort, :edited => selection.edited}
            end
          end
        end
        @h_statuses={}
        Status.all.map{|s| @h_statuses[s.id]=s}
        @h_steps={}
        all_steps = Step.all
        all_steps.map{|s| @h_steps[s.id]=s}
        @h_steps_by_name = {}
        all_steps.map{|s| @h_steps_by_name[s.name] = s}

        ## update viewed_at
        @project.update_attribute(:viewed_at, Time.now)
        
        # elsif @project.archive_status_id == 2 ## project is not unarchived
        #  @error = "The project is being unarchived..."
      end
    else
      @error = "The project doesn't exist or the session has expired. Please create a new project."
    end
  end
    
  def get_hca_data #h_p

    @nber_hits_displayed = 200
    @h_hca= {} #JSON.parse(h_p[:q])

    #    @h_filters = {
    #     'file' => {'fileFormat' => {"is" => ["matrix"]}}
    #    }
    
    #    if h_p[:filters]
    #      @h_filters.merge(h_p[:filters])
    #    end
    
    #    @h_urls = {
    #      :summary => "https://service.dev.explore.data.humancellatlas.org/repository/summary?filters=#{@h_filters.to_json}",
    #      :projects => "https://service.dev.explore.data.humancellatlas.org/repository/projects?filters=#{@h_filters.to_json}&size=15"
    #    }

    @h_filters = JSON.parse(params[:q]) if params[:q]
   
    @h_urls = {
      :summary => "https://service.explore.data.humancellatlas.org/repository/summary?filters=#{params[:q]}",
      :projects => "https://service.explore.data.humancellatlas.org/repository/projects?filters=#{params[:q]}&size=#{@nber_hits_displayed}"
    }

    errors = []
    @log = ""
    @h_urls.each_key do |k|
      cmd = "wget -O - '#{@h_urls[k]}'"
      @log +="=>" +cmd + "<= " 
      tmp_data = `#{cmd}`
      @h_hca[k]= {}

      if !tmp_data.empty?
        begin
          @h_hca[k] = JSON.parse(tmp_data)
        rescue Exception => e
          errors.push("Data from HCA is not accessible at this time.")
        end
      end
    end
  end

  def hca_preview

    h_p = {}
    begin
      h_p = JSON.params[:q] if params[:q]
    rescue Exception => e
    end
    
    get_hca_data()

    render :partial => 'hca_preview'
  end

  def hca_download
  end

  # GET /projects/new
  def new
    project_key = (current_user) ? create_key() : session[:sandbox]

    ### reset upload

    h = {:upload_type => 1, :project_key => project_key, :user_id => (current_user) ? current_user.id : 1}
    @fu_inputs = Fu.where(h).all
     
    if @fu_inputs.count > 0
      @fu_inputs.to_a.each do |fu_input|
        if fu_input.upload_file_name
          file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu_input.id.to_s + fu_input.upload_file_name
          File.delete file_path if File.exist?(file_path)
        end
        fu_input.destroy
        # end
      end
    end

    h[:status]= 'new'
    @fu_input = Fu.new(h)
    @fu_input.save!
    
    ### reset project

    @project = Project.where(:key => project_key).first
    if @project and editable? @project
      delete_project(@project)
    end
 
    @project = Project.new
    @project.key = project_key
    @shares = @project.shares.to_a
  
    ### get initial HCA data
    #get_hca_data()

  end

  # GET /projects/1/edit
  def edit
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    @existing_group_file = 1 if File.exist?(tmp_dir + "parsing" + "group.tab")
    @h_steps={}
    @results = {}
    @all_results = {}
    @shares = @project.shares.to_a
    Step.all.map{|s| @h_steps[s.id]=s}
    active_step_name = @h_steps[session[:active_step]].name
 #  get_results()
    respond_to do |format|
      format.html {
        if params[:global]
          render :partial => "edit"
        else
          @h_attrs_parsing = JSON.parse(@project.parsing_attrs_json) if @project.parsing_attrs_json
          render :partial => "form_" + active_step_name 
        end
      }#:layout => nil }
    end
  end

  def manage_access
    existing_shares = @project.shares
    
    if params[:shares]
      #   h_existing_emails = {}
      h_shares = {}
      existing_shares.each do |share|
        #     h_existing_emails[share.email]=share
        h_shares[share.id]=share
      end
      
#      params[:sids].split(",").each do |sid|
      params[:shares].to_unsafe_h.each_key do |sid|
        h = {
          :analyze_perm => params[:shares][sid]['analyze_perm'],
          :export_perm => params[:shares][sid]['export_perm']
        }
        h_shares[sid.to_i].update_attributes(h)
      end
      
    end

    existing_shares.each do |share|
      if !params[:shares] or !params[:shares][share.id.to_s]
        share.update_attributes(:analyze_perm => false, :export_perm => false)
      end
    end
    ### read access
    #  if  @project.read_access
    #    @project.read_access.split(/\s*,\s*/).map{|e| e.gsub(/\s+/, '')}.each do |email|
    #      h_share={:read_access => true, :write_access => false}
    #      u = User.where(:email => email.downcase).first
    #      if u
    #        h_detected_users[u.id]=1
  #        if h_existing_users[u.id]
  #          h_existing_users[u.id].update_attributes(h_share)
  #        else
  #          h_share.merge({:user_id => u.id, :project_id => @project.id}) 
  #          share = Share.new(h_share)
  #          share.save
  #        end
  #      end
  #    end
  #  end
    
    ### write access
   # if  @project.write_access
   #   @project.write_access.split(/\s*,\s*/).map{|e| e.gsub(/\s+/, '')}.each do |email|
   #     h_share={:read_access => true, :write_access => true}
   #     u = User.where(:email => email.downcase).first
   #     h_detected_users[u.id]=1
   #     if u
   #       if h_existing_users[u.id]
   #         h_existing_users[u.id].update_attributes(h_share)
   #       else
   #         h_share.merge({:user_id => u.id, :project_id => @project.id})
   #         share = Share.new(h_share)
   #         share.save
   #       end
   #     end
   #   end
   # end

    ## reset accesses
    #    existing_shares.each do |share|
    #      if !h_detected_users[share.email]
    #        #        share.update_attributes(h_share)
    #        share.destroy
    #      end
    #    end
    
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    @h_formats = {}
    FileFormat.all.map{|f| @h_formats[f.name] = f}
    #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
    #    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
    #    tmp_dir += @project.key
    #    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

    ### delete project if already exists with this key    
    if p = Project.where(:key => @project.key).first and editable? p
      delete_project(p)
    end
    
    tmp_attrs = params[:attrs] || {}
    tmp_attrs[:has_header] = 1 if tmp_attrs[:has_header]
    tmp_attrs[:file_type] = 'LOOM' if !tmp_attrs[:file_type] ### HCA import case
    [:file_type, :sel_name, :nber_cols, :nber_rows, :sel_hca_projects].each do |k|
      tmp_attrs[k] = params[k] if params[k] and !params[k].strip.empty?
    end
    if @h_formats[tmp_attrs[:file_type]].child_format != 'RAW_TEXT' ## delete the RAW_TEXT parsing options
      [:delimiter, :col_gene_name, :has_header].each do |k|
        tmp_attrs.delete(k)
      end
    end
    @project.parsing_attrs_json = tmp_attrs.to_json
    @project.nber_cols = params[:nber_cols]
    @project.nber_rows = params[:nber_rows]
    @project.user_id = (current_user) ? current_user.id : 1
    @project.sandbox = (current_user) ? false : true
    @project.session_id = (s = Session.where(:session_id => session.id).first) ? s.id : nil
    @project.version_id = Version.last.id

    input_file = Fu.where(:project_key => @project.key).first
    file_path = nil
    if input_file and input_file.upload_file_name
      @project.input_filename = input_file.upload_file_name      
      file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + input_file.id.to_s + input_file.upload_file_name
      logger.debug("CMD_ls0 " + `ls -alt #{file_path}`)
    end
    
    default_diff_expr_filters = {
      :fc_cutoff => '2',
      :fdr_cutoff => '0.05'
    }    
    @project.diff_expr_filter_json = default_diff_expr_filters.to_json
    
    default_gene_enrichment_filters = {
      :fdr_cutoff => '0.05'
    }
    @project.gene_enrichment_filter_json = default_gene_enrichment_filters.to_json

#    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
#    File.delete tmp_dir + ('input.' + @project.extension) if File.exist?(tmp_dir + ('input.' + @project.extension))
    # logger.debug("1. File #{file_path} exists!") if File.exist?(file_path)

    respond_to do |format|
      if ((input_file and input_file.upload_file_name) or params[:sel_hca_projects] != '{}' ) and @project.save
        
        session[:active_dr_id] = 1
        
        # initialize directory
        tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        tmp_dir += @project.key
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        
        if input_file and input_file.upload_file_name
          
          ### get extension                                                                                                                                                   
          ext = input_file.upload_file_name.split(".").last
          if !['zip', 'bz', 'bz2', 'gz', 'h5', 'loom'].include? ext
            ext = 'txt'
          end
          
          ### set the project id to the upload file
          
          input_file.update_attributes(:project_id => @project.id)
          
          ### link upload to working directory
          upload_path =  Pathname.new(APP_CONFIG[:upload_data_dir]) + input_file.id.to_s + input_file.upload_file_name
          #`dos2unix #{upload_path}`
          #`mac2unix #{upload_path}`        
          ### to be sure because normally it is already deleted
          #          File.delete tmp_dir + ('input.' + ext) if File.exist?(tmp_dir + ('input.' + ext))
          # ext = input_file.upload_file_name.split(".").last
          # if ext != 'zip' and ext != 'gz'
          #   ext = 'txt'
          # end
          
          File.delete tmp_dir + ('input.' + ext) if File.exist?(tmp_dir + ('input.'+ ext))
          File.symlink upload_path, tmp_dir + ('input.' + ext) 
          #        logger.debug("2. File #{file_path} exists!") if File.exist?(file_path)
          ### parse batch_file
          
          #        @project.parse_batch_file()
        else
          ext = 'loom'
        end

        @project.update_attribute(:extension, ext)

        ### init project_steps
        
        (1 .. Step.count).each do |step_id|
          project_step = ProjectStep.where(:project_id => @project.id, :step_id => step_id).first
          if !project_step
            project_step = ProjectStep.new(:project_id => @project.id, :step_id => step_id, :status_id => (step_id == 1) ? 1 : nil  )
            project_step.save
          end
        end
        
        ### read_write access

        manage_access()
     #   logger.debug("3. File #{file_path} exists!") if File.exist?(file_path)
        
        @project.parse_files()
     #   logger.debug("4. File #{file_path} exists!") if File.exist?(file_path)
        
        #        @project.parse()
        session[:active_step]=1
        format.html { redirect_to project_path(@project.key) #, notice: 'Project was successfully created.'
        }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update

    require "csv"

    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    
    @h_steps={}
    Step.all.map{|s| @h_steps[s.id]=s}

    if params[:project][:step_id]
#      session[:active_step]= params[:project][:step_id]
      (params[:project][:step_id].to_i + 1 .. Step.all.size).to_a.each do |step_id|
        project_step = ProjectStep.where(:project_id => @project.id, :step_id => step_id).first
        project_step.update_attribute(:status_id, nil)
      end
      project_step = ProjectStep.where(:project_id => @project.id, :step_id => params[:project][:step_id]).first
      project_step.update_attributes(:status_id => 1)
      params[:project][:status_id]=1
      params[:project][:duration]=0
      step = @h_steps[params[:project][:step_id].to_i] # Step.where(:id => params[:project][:step_id].to_i).first
      params[:attrs]||={}
      params[:project][(step.obj_name + "_attrs_json").to_sym]=(params[:attrs].keys.size > 0) ? params[:attrs].to_json : "{}" 
    else ### update of project details 
      
      #@project.parse_batch_file()
    #  cmd = "rails parse_batch_file[#{@project.key}]"
    #  `#{cmd}`
      
      ### if organism changes, update the gene file                                                                                                                                                
      if @project.organism_id != params[:project][:organism_id].to_i
        #    parsing_dir =  tmp_dir + 'parsing'
        #    gene_names_file = parsing_dir + 'gene_names.json'
        #    cmd = "java -jar #{Rails.root}/lib/ASAP.jar -T RegenerateNewOrganism -organism #{params[:project][:organism_id]} -j #{gene_names_file} -o #{parsing_dir}"
        #    logger.debug("CMD: " + cmd)
        #    `#{cmd}`
        #    
        #    ### rewrite download files
        #    Step.where(["id <= ?", @project.step_id]).all.select{|e| e.id < 4}.each do |step|
        #      output_dir =  tmp_dir + step.name 
        #      output_file = output_dir + 'output.tab'
        #      cmd = "java -jar #{Rails.root}/lib/ASAP.jar -T CreateDLFile -f #{output_file} -j #{gene_names_file} -o #{output_dir + 'dl_output.tab'}"
        #      logger.debug("CMD: " + cmd)
        #      `#{cmd}`
        #    end
        
        
        ### delete pending jobs on gene_enrichment and de                                                                                                                                                                     
        list_pending_jobs = @project.jobs.select{|j| [6, 7].include?(j.step_id) and j.status_id == 1}
        Delayed::Job.where(:id => list_pending_jobs.map{|j| j.delayed_job_id}).all.destroy_all
        list_pending_jobs.map{|j| j.destroy}
        
        ### remove foreign keys
        
        @project.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
        @project.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
        
        ### kill current jobs                                                                                                                                                                        
        
        Basic.kill_jobs(logger, @project.id, 6, @project)
        Basic.kill_jobs(logger, @project.id, 7, @project)

        
        ## delete existing DE et gene enrichments
        @project.gene_enrichments.destroy_all
        @project.diff_exprs.destroy_all
        
      end
      
      #      ### read_write access      
      #      manage_access()

    end
    respond_to do |format|
      if @project.update(project_params)
        
        ### read_write access                                                                                                                                   
        manage_access()

        if params[:project][:step_id]

          list_steps = (params[:project][:step_id].to_i .. 7).to_a

          ### remove foreign keys to jobs  

          list_steps.each do |step_id|
            if step_id == 1
              @project.update_attribute(:parsing_job_id, nil)
            elsif step_id == 2
              @project.update_attribute(:filtering_job_id, nil)
            elsif step_id == 3
              @project.update_attribute(:normalization_job_id, nil)
            elsif step_id == 4
              @project.project_dim_reductions.each do |pdr|
                pdr.update_attribute(:job_id, nil)
              end
            elsif step_id == 5
              @project.clusters.map{|cluster| cluster.update_attribute(:job_id, nil)}
            elsif step_id == 6
              @project.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
            elsif step_id == 7
              @project.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
            end
          end
          
          ### remove pending delayed jobs
          list_pending_jobs = @project.jobs.select{|j| list_steps.include?(j.step_id) and j.status_id == 1}
          Delayed::Job.where(:id => list_pending_jobs.map{|j| j.delayed_job_id}).all.destroy_all
          list_pending_jobs.map{|j| j.destroy}

          
          ### kill jobs
          list_steps.each do |step_id|
            if step_id !=4
              Basic.kill_jobs(logger, @project.id, step_id, @project)
            else
              @project.project_dim_reductions.each do |pdr|
                Basic.kill_jobs(logger, @project.id, step_id, pdr)
              end
            end
          end

          #### remove files
          list_steps.each do |step_id|
            if ! (step_id == 5 and params[:project][:step_id].to_i == 3)
              ProjectStep.where(:project_id => @project.id, :step_id => step_id).all.each do |ps|
                step_name = ps.step.name
                if File.symlink?(tmp_dir + step_name)
                  File.delete(tmp_dir + step_name)
                else
                  FileUtils.rm_r Dir.glob((tmp_dir + step_name).to_s + "/*")
                end
                ps.update_attributes(:status_id => nil) if ps.step_id != params[:project][:step_id].to_i
                logger.debug("PROJECTSTEP: " + ps.to_json)
              end
            end
          end
          
          ### clean existing clusters / de analyses / visualization / diff_exprs                                                                                                                                                              
          if params[:project][:step_id].to_i < 4
            @project.gene_enrichments.destroy_all
            @project.diff_exprs.destroy_all
            @project.project_dim_reductions.destroy_all
            @project.clusters.select{|c| !c.step_id or c.step_id > 2}.map{|c| c.destroy} if params[:project][:step_id].to_i != 3
          end
             
          if @project.step_id==1
            @project.parse_files()
          elsif @project.step_id==2
            @project.run_filter()
          elsif @project.step_id==3
            @project.run_norm()          
          end

          ### kill processes that are in steps > @project.step_id

          #          if @project.step_id < 4 ###kill the latest pid running
          #            if @project.pid and `ps -ef | grep pid`
          #              Process.kill("KILL", @project.pid)
          #            end
          #          end
          #def killPid(cmd)
          #   pid=exec("pidof #{cmd}")
          #   Process.kill "USR2", pid
          #end
        end

 
        format.html {
          if params[:render_nothing] and step
   #         jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step]).all.to_a
   #         jobs.sort!{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')} if jobs.size > 0
   #         last_job = jobs.last
   #         last_update = @project.status_id.to_s + ","
   #         last_update += [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job
   #           logger.debug("COUNT_JOBS 2:" + jobs.size.to_s + " -> " + jobs.last.updated_at.to_s)
            @last_update =  get_last_update_status()
          #  if session[:last_update_active_step] != last_update 
          #    @reload_step_container = 1
          #    session[:last_update_active_step] = last_update
          #  end
            
            render :partial => 'pipeline_upd2' #:nothing => true
          else
            ### reset active_step
            session[:override_active_step]=1
            redirect_to project_path(@project.key), notice: '' 
          end
        }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_project(p)


      ## remove foreign keys to jobs    
      p.update_attributes(:parsing_job_id => nil, :filtering_job_id => nil, :normalization_job_id => nil)
      p.project_dim_reductions.map{|de| de.update_attribute(:job_id, nil)}
      p.clusters.map{|cluster| cluster.update_attribute(:job_id, nil)}
      p.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
      p.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
      
      ### kill jobs
      list_steps = (1 .. 7).to_a
      list_steps.each do |step_id|
        if step_id !=4
          Basic.kill_jobs(logger, p.id, step_id, p)
        else
          p.project_dim_reductions.each do |pdr|
            Basic.kill_jobs(logger, p.id, step_id, pdr)
          end
        end
      end
      
      ## delete files                                                                                            
      new_tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((p.user_id == nil) ? '0' : p.user_id.to_s) + p.key
      FileUtils.rm_r new_tmp_dir if File.exist?(new_tmp_dir)
      
    # delete objects
    p.shares.destroy_all
    p.annots.destroy_all
    p.del_runs.destroy_all
    p.active_runs.destroy_all
    p.fos.destroy_all
    p.runs.destroy_all

    p.reqs.destroy_all
      #p.fus.destroy_all
      p.project_steps.destroy_all
      p.gene_enrichments.destroy_all
      p.diff_exprs.destroy_all
      p.project_dim_reductions.destroy_all
      p.selections.destroy_all
      p.clusters.destroy_all
      p.gene_sets.destroy_all
      # p.jobs.select{|j| j.status_id == 1}.map{|j| j.destroy}
      list_pending_jobs = p.jobs.select{|j| j.status_id == 1}
      Delayed::Job.where(:id => p.jobs.map{|j| j.delayed_job_id}).all.destroy_all
      list_pending_jobs.map{|j| j.destroy}
    
    ### delete fus
    p.fus.map{|fu|
      file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu.id.to_s + fu.upload_file_name
      File.delete file_path if File.exist?(file_path)
    }
    p.fus.destroy_all
#    p.runs.destroy_all

    p.destroy

  end
  
  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    
    if editable? @project
      delete_project(@project)
    end
    get_projects()

    @h_archive_statuses = {}
    ArchiveStatus.all.map{|s| @h_archive_statuses[s.id] = s}
    @h_statuses = {}
    Status.all.map{|o| @h_statuses[o.id]=o}
    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id]=o}
    
    respond_to do |format|
      #      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.html {
        render :partial => 'index'
      }
      
      format.json { head :no_content }
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    
    @project = Project.find_by_key(params[:key])
    
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    #      params.fetch(:project, {})
  
    params.fetch(:project).permit(:name, :key, :organism_id, :group_filename, :input_filename, :status_id, :duration, :step_id, :filter_method_id, :norm_id, :parsing_attrs_json, :filter_method_attrs_json, :norm_attrs_json, :public, :pmid, :diff_expr_filter_json, :gene_enrichment_filter_json, :read_access, :write_access)
  end
end
  
