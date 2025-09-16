module Basic

  #class Basic

  class << self

    def generate_project_json p

      h_references = {}
      Article.all.map{|a| h_references[a.doi] = a}
      h_organisms = {}
      Organism.all.map{|e| h_organisms[e.id] = e}
      h_identifier_types = {}
      IdentifierType.all.map{|it| h_identifier_types[it.id] = it}
      h_cla_sources = {}
      ClaSource.all.map{|cla_source| h_cla_sources[cla_source.id] = cla_source}
      h_cell_ontologies = {}
      CellOntology.all.map{|co| h_cell_ontologies[co.id] = co}
      h_envs = {}
      Version.all.map{|v| h_envs[v.id] = Basic.safe_parse_json(v.env_json, {})}
      h_steps = {}
      Step.all.map{|s| h_steps[s.id] =s}
      h_std_methods = {}
      StdMethod.all.map{|s| h_std_methods[s.id] = s}
      h_project_types = {}
      ProjectType.all.map{|e| h_project_types[e.id] = e}
      
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
      
      h_env = h_envs[p.version_id]
      asap_data_db = "asap_data_v#{h_env['asap_data_db_version']}"

      clas = Cla.where(:project_id => p.id).all.map{|e|

        up_genes = (e.up_gene_ids and e.up_gene_ids.size > 0) ? Basic.sql_query2(:asap_data, h_env['asap_data_db_version'], 'genes', '', '*', "id in (#{e.up_gene_ids})").map{|g| Basic.format_gene(g)} : nil
        # logger.debug(e.up_gene_ids.split(","))                                                                                                                                                                                               
        down_genes = (e.down_gene_ids and e.down_gene_ids.size > 0) ? Basic.sql_query2(:asap_data, h_env['asap_data_db_version'], 'genes', '', '*', "id in (#{e.down_gene_ids})").map{|g| Basic.format_gene(g)} : nil

        cots =  (e.cell_ontology_term_ids) ?
        CellOntologyTerm.where(:id => e.cell_ontology_term_ids.split(",")).all.map{|cot|
          {
            :identifier => cot.identifier,
            :name => cot.name,
            :description => cot.description,
            :ontology => h_cell_ontologies[cot.cell_ontology_id].name
          }
        } : nil

        {
          :id => e.id,
          :num => e.num,
          :name => e.name,
          :cell_set_key => (cs = e.cell_set) ? cs.key : nil,
          :comment => e.comment,
          :project_id => e.project_id,
          :clone_id => e.clone_id,
          :cat => e.cat,
          :cat_idx => e.cat_idx,
          :cell_ontology_terms => cots || [],
          :annot_id => e.annot_id,
          :up_genes => up_genes,
          :down_genes => down_genes,
          :orcid_user => OrcidUser.where(:id => e.orcid_user_id).first,
          :user_id => (u = User.where(:id => e.user_id).first) ? u.email : nil,
          :source => (e.cla_source_id and h_cla_sources[e.cla_source_id]) ? h_cla_sources[e.cla_source_id].name : nil,
          :nber_agree => e.nber_agree,
          :nber_disagree => e.nber_disagree,
          :score => e.nber_agree - e.nber_disagree,
          :obsolete => e.obsolete,
          :created_at => e.created_at,
          :updated_at => e.updated_at
        }
      }
      h_annots = {}
      h_clas = {}
      clas.map{|cla|
        h_annots[cla[:annot_id]] = {};
        h_clas[cla[:annot_id]] ||= [];
        h_clas[cla[:annot_id]].push cla
      }

      if p.public_id == 93
        #puts clas.to_json
        #   puts h_clas.to_json
      end

      Annot.where(:id => h_annots.keys).all.map{|a| h_annots[a.id] = a}
      annotation_groups = []
      h_annots.each_key do |annot_id|
        annot = h_annots[annot_id]
        run = Run.where(:id => annot.run_id).first
        lineage_runs = Run.where(:id => run.lineage_run_ids.split(",")).all + [run]
        h_command = Basic.safe_parse_json(run.command_json, {})
        #  command = (h_command['docker_call']) ? h_command['docker_call'].gsub(project_dir.to_s, "$PROJECT_DIR") : nil
        command = Basic.build_cmd(h_command).gsub(project_dir.to_s, "$PROJECT_DIR").gsub(/postgres\:\d+\/asap2_data_v\d+/, ('$ASAP_DATA_DB_HOST:$ASAP_DATA_DB_PORT/' + asap_data_db))
        docker_container = ""
        if h_command['docker_call'] and m = h_command['docker_call'].match(/([\w\d\:\/]+) -c$/)
          docker_container = m[1]
        end
        origin = lineage_runs.map{|e|
          {
            :run_id => e.id,
            :step => h_steps[e.step_id].label,
            :std_method => h_std_methods[e.std_method_id].label,
            :num => e.num,
            :attrs => Basic.safe_parse_json(e.attrs_json, {}),
            :command => ((h_steps[e.step_id].name != 'parsing') ? command : nil),
            :docker_repo => "dockerhub",
            :docker_container_url => nil,
            :docker_container_name => docker_container
          }
        }
        annotation_group = {
          :origin => origin,
          :annot_id => annot.id,
          :annot_run_id => annot.run_id,
          :metadata => annot.name,
          :annotations => h_clas[annot_id].select{|e| e[:num] and e[:score]}.sort{|a, b| [b[:score], a[:num]] <=> [a[:score], b[:num]]}
        }
        annotation_groups.push annotation_group
      end
      h = {
        :public_key => p.public_key,
        :key => p.key,
        :doi => p.doi,
        :asap_data_db => asap_data_db,
        :asap_data_db_url => APP_CONFIG[:server_url] + "/dumps/#{asap_data_db}.sql.gz",
        :version => "v" + p.version_id.to_s,
        :reproducibility_instructions_url => APP_CONFIG[:server_url] + "/projects/#{p.key}/instructions",
        :reproducibility_script_url => APP_CONFIG[:server_url] + "/projects/#{p.key}/get_commands",
        :nber_cols => p.nber_cols,
        :nber_rows => p.nber_rows,
        :reference => h_references[p.doi],
        :tissue => p.tissue,
        :technology => p.technology,
        :extra_info => p.extra_info,
        :tax_id => h_organisms[p.organism_id].tax_id,
        :organism => h_organisms[p.organism_id].name,
        :cloned_project_id => p.cloned_project_id,
        :project_type => (h_project_types[p.project_type_id]) ? h_project_types[p.project_type_id].name : nil,
        :nber_cloned => p.nber_cloned,
        :nber_views => p.nber_views,
        :disk_size_archived => p.disk_size_archived,
        :project_cell_set_key => (pcs = p.project_cell_set) ? pcs.key : nil,
        :experiments => p.exp_entries.map{|e|
          {
            :identifier_type => h_identifier_types[e.identifier_type_id].name,
            :identifier =>  e.identifier,
            :url => h_identifier_types[e.identifier_type_id].url_mask.gsub(/\#\{id\}/, e.identifier)
          }
        },
        :annotation_groups => annotation_groups
      }

      h_cots = {}
      CellOntologyTerm.where(:id => OtProject.where(:project_id => p.id).all.map{|e| e.cell_ontology_term_id}.uniq).all.each do |cot|
        h_cots[cot.id] = cot
      end
      
      OntologyTermType.all.each do |ott|
        ott_key = ott.name
        ot_projects = OtProject.where(:ontology_term_type_id => ott.id, :project_id => p.id).all
        ott_project = OttProject.where(:ontology_term_type_id => ott.id, :project_id => p.id).first
        if ott_project and ott_project.not_applicable
          h[ott_key] = nil
        else
          h[ott_key] = ot_projects.map{|otp|
            {
              :identifier => (cot_id = otp.cell_ontology_term_id) ? h_cots[cot_id].identifier : nil,
              :name => (cot_id) ? h_cots[cot_id].name : otp.free_text,
              :from_metadata => (otp.annot_id and h_annots[otp.annot_id]) ? h_annots[otp.annot_id].name : nil
            }
          }
        end
        
      end
      
      return h

    end

      def format_gene g

    return {
      :name => g['name'],
      :ensembl_id => g['ensembl_id'],
      :biotype => g['biotype'],
      :chr => g['chr'],
      :ncbi_gene_id => g['ncbi_gene_id'],
      :latest_ensembl_release => g['latest_ensembl_release'],
      :description => g['description'],
      :function_description => g['function_description'],
      :alt_names => g['alt_names']
    }

  end


    def upd_project_cell_set p

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
      
      puts "get cells..."
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + 'parsing' + 'output.loom'} -meta /col_attrs/CellID"
      output = `#{cmd}` 
      File.open(project_dir + 'parsing' + 'cell_ids', 'w') do |fout|
        fout.write(output)
      end
      res = Basic.safe_parse_json(output, {})
      cells = res['values']
      
      if cells and cells.size > 0
        
        dataset_md5 = Digest::MD5.hexdigest({:cells => cells.sort}.to_json)
        
        pc = ProjectCellSet.where(:key => dataset_md5).first
        if !pc
          pc = ProjectCellSet.new(:key => dataset_md5, :nber_cells => cells.size)
          pc.save
        else
          pc.update_attributes({:nber_cells => cells.size})
        end
        
        p.update_attributes({:project_cell_set_id => pc.id})
        
      end
    end
    
    def get_s3_settings
      s3_settings_file = Pathname.new(Rails.root) + 'config' + '.s3.json'
      h_s3_settings = JSON.parse(File.read(s3_settings_file))
      return h_s3_settings
    end
    
    
    def connect_s3 s3b, h_s3_settings
      Aws.config.update({
                          :endpoint => s3b[:endpoint],
                          :region => s3b[:region],
                          :access_key_id => h_s3_settings[s3b[:key]]["rw"][0],
                          :secret_access_key => h_s3_settings[s3b[:key]]["rw"][1]
                        })
      return Aws::S3::Client.new
    end
    
    def connect_resource_s3 s3b, h_s3_settings ### for upload on S3                                                                                                 
      Aws.config.update({
                          :endpoint => s3b[:endpoint],
                          :region => s3b[:region],
                          :access_key_id => h_s3_settings[s3b[:key]]["rw"][0],
                          :secret_access_key => h_s3_settings[s3b[:key]]["rw"][1]
                        })
      return Aws::S3::Resource.new
    end
    
    
    def write_file_from_s3 s3, bucket_id, project, filepath
      d = filepath.to_s.split("/")
      filename = d.pop
      FileUtils.mkpath d.join("/")
      return_val = false
      File.open(filepath, 'wb') do |file|
        begin
          puts "METADATA: " + s3.get_object(bucket: bucket_id, key: project.key).metadata.to_json
          s3.get_object(bucket: bucket_id, key: project.key) do |chunk, headers|
            # headers['content-length']                                                                                                                               
            file.write(chunk)
            return_val = true
          end
        rescue Exception => e
          puts e.message + " : " + e.backtrace.to_json
          return_val = false
        end
      end
      return return_val
    end
    
    def write_file_on_s3 s3b, filepath, metadata
      h_s3_settings = get_s3_settings()
      bucket = connect_resource_s3(s3b, h_s3_settings).bucket(s3b[:key])
      obj = bucket.object(metadata[:key])
      metadata.delete(:key)
      puts "Writing on S3"
      begin
        obj.upload_file(filepath, :metadata => metadata)     
        return obj
      rescue Exception => e
        return nil
      end
      
    end

    def get_asap_docker version
      h_env = JSON.parse(version.env_json)
      list_docker_image_names = h_env['docker_images'].keys.map{|k| h_env['docker_images'][k]["name"] + ":" + h_env['docker_images'][k]["tag"]}
      docker_images = DockerImage.where("full_name in (" + list_docker_image_names.map{|e| "'#{e}'"}.join(",") + ")").all
      asap_docker_image = docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
      return asap_docker_image
    end
    
    def find_marker_enrichment logger, project, meta, find_marker_run, user_id
      t = Time.now
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
      version = project.version
      h_env = JSON.parse(version.env_json)
      
      #   list_docker_image_names = h_env['docker_images'].keys.map{|k| h_env['docker_images'][k]["name"] + ":" + h_env['docker_images'][k]["tag"]}
      #   docker_images = DockerImage.where("full_name in (#{list_docker_image_names.map{|e| "'#{e}'"}.join(",")})").all
      #   asap_docker_image = docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
      asap_docker_image = get_asap_docker(version)
      
#      find_marker_step = Step.where(:version_id => project.version_id, :name => 'markers').first
      find_marker_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'markers').first 
#      find_marker_enrichment_step = Step.where(:version_id => project.version_id, :name => 'marker_enrich').first
      find_marker_enrichment_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'marker_enrich').first
      #      std_method = StdMethod.where(:version_id => project.version_id, :name => 'asap_marker_enrichment').first
      std_method = StdMethod.where(:docker_image_id => asap_docker_image.id, :name => 'asap_marker_enrichment').first
      
      h_cmd_params = JSON.parse(find_marker_step.command_json)
      tmp_h = JSON.parse(std_method.command_json)
      tmp_h.each_key do |k|
        h_cmd_params[k] = tmp_h[k]
      end
      
      docker_image = h_cmd_params['docker_image']
      
      matrix = Annot.where(:project_id => project.id, :dim => 3, :name => "/matrix", :filepath => meta.filepath).first
      
      last_run = Run.where(:project_id => project.id, :step_id => find_marker_step.id).order("id desc").first
      if find_marker_run
        input_dir = project_dir + find_marker_step.name + find_marker_run.id.to_s
        puts "MARKER_ENRICH_STEP: " + find_marker_enrichment_step.to_json
        puts "MARKER_ENRICH_METHOD: " + std_method.to_json
        
        h_data_classes = {}
        DataClass.all.map{|dc| h_data_classes[dc.id] = dc}
        
        puts "TEST_ENRICH: " + meta.to_json
        
        if matrix and meta #and last_run                                                                                         
          puts "TEST_ENRICH2: " + meta.to_json
          genesets = Basic.sql_query2(:asap_data, h_env['asap_data_db_version'], 'gene_sets', '', 'id', "organism_id = #{project.organism_id}")
          
          h_attrs = {
            :input_dir => input_dir,
            :nber_files => Dir.new(input_dir).entries.select{|e| !e.match(/^\./) and e.match(/cat_\d+.tsv/)}.size,
            :geneset_ids => genesets.map{|gs| gs.id}.join(",")          
          }
          
          h_run = {
            :project_id => project.id,
            :step_id => find_marker_enrichment_step.id,
            :std_method_id => std_method.id,
            :status_id => 6, #status_id, # set as running                                                                                 
            :num => (last_run) ? last_run.num + 1 : 1,
            :user_id => user_id,
            :command_json => "{}", #h_cmd.to_json,                          
            :attrs_json => h_attrs.to_json, #self.parsing_attrs_json,
            :output_json => "{}", #h_outputs.to_json,
            :lineage_run_ids => '{}', #lineage_run_ids.join(","),
            :submitted_at => Time.now,
            :pipeline_parent_run_ids => find_marker_run.id
          }
          
          
          if find_marker_enrichment_step and std_method
            
            puts "h_run: " + h_run.to_json 
            run = Run.where({:project_id => project.id,
                              :step_id => find_marker_enrichment_step.id,
                              :std_method_id => std_method.id,
                              :attrs_json => h_attrs.to_json
                            }).first
            if run
              run.update_attributes(h_run)
            else
              run = Run.new(h_run)
              run.save
            end
            
            output_dir =  project_dir + find_marker_enrichment_step.name
            Dir.mkdir output_dir if !File.exist? output_dir
            output_dir += run.id.to_s
            if File.exist? output_dir
              FileUtils.rm_r output_dir
            end
            Dir.mkdir output_dir
            
            # set run                                                                                                   
            h_run_attrs = JSON.parse(run.attrs_json)
            h_res = Basic.get_std_method_attrs(std_method, find_marker_step)
            h_attrs = h_res[:h_attrs]
            #    @h_global_params = h_res[:h_global_params]                                                                                                                                            
            h_p = {
              :project => project,
              :h_cmd_params => h_cmd_params,
              :run => run,
              :p => h_run_attrs, #list_of_runs2[run_i][1],                                                                                                                                   
              :h_attrs => h_attrs,
              :step => find_marker_step,
              :h_data_classes => h_data_classes,
              :std_method => std_method,
              :h_env => h_env,
              :el_time => t,
              :user_id => user_id #(current_user) ? current_user.id : 1                                                                                                                      
            }
            h_res = Basic.set_run(logger, h_p)
      
            children_runs = JSON.parse(find_marker_run.children_run_ids)
            children_runs.push run.id if !children_runs.include? run.id
            find_marker_run.update_attribute(:children_run_ids, children_runs.to_json)

          end          
          
        end
        
      end
    end

    def find_markers logger, project, meta, user_id

      t = Time.now
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
      version = project.version
      h_env = JSON.parse(version.env_json)
      #      list_docker_image_names = h_env['docker_images'].keys.map{|k| h_env['docker_images'][k]["name"] + ":" + h_env['docker_images'][k]["tag"]}
      #      docker_images = DockerImage.where("full_name in (#{list_docker_image_names.map{|e| "'#{e}'"}.join(",")})").all
      #      asap_docker_image = docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
      asap_docker_image = get_asap_docker(version)
      #find_marker_step = Step.where(:version_id => project.version_id, :name => 'markers').first
      find_marker_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'markers').first 

      # std_method = StdMethod.where(:version_id => project.version_id, :name => 'asap_markers').first
      std_method = StdMethod.where(:docker_image_id => asap_docker_image.id, :name => 'asap_markers').first 
      
      h_cmd_params = JSON.parse(find_marker_step.command_json)
      tmp_h = JSON.parse(std_method.command_json)
      tmp_h.each_key do |k|
        h_cmd_params[k] = tmp_h[k]
      end

      docker_image = h_cmd_params['docker_image']
      
      #   parsing_matrix = Annot.where(:project_id => project.id, :dim => 3, :name => "/matrix", :filepath => "parsing/output.loom").first
      matrix = Annot.where(:project_id => project.id, :dim => 3, :name => "/matrix", :filepath => meta.filepath).first
      # puts parsing_matrix

      matrix_run = Run.where(:project_id => project.id, :id => matrix.run_id).first      

      last_run = Run.where(:project_id => project.id, :step_id => find_marker_step.id).order("id desc").first

      h_data_classes = {}
      DataClass.all.map{|dc| h_data_classes[dc.id] = dc}
      
      if matrix and meta #and last_run
        h_attrs = {
  #        #        {"input_de":{"annot_id":168794,"run_id":32390},"fdr_cutoff":"0.05","fc_cutoff":"2","gene_set_id":"672","adj_method":"fdr","min":"15","max":"500"}
#          :input_matrix_filename => project_dir + meta.filepath,
#          :input_matrix_dataset => '/matrix',
          :input_matrix => {"annot_id" => matrix.id,"run_id" => matrix.run_id},
          :groups_filename => project_dir + meta.filepath, #[{:annot_id => matrix.id, :run_id => matrix.run_id, :output_filename => matrix.filepath}],
          :groups_dataset => meta.name,
          :groups_id => meta.id
        }

        h_run = {
          :project_id => project.id,
          :step_id => find_marker_step.id,
          :std_method_id => std_method.id,
          :status_id => 6, #status_id, # set as running      
          :num => (last_run) ? last_run.num + 1 : 1,
          :user_id => user_id,
          # :command_json => "{}", #h_cmd.to_json,        
          :command_json => "{}", #h_cmd.to_json,
          :attrs_json => h_attrs.to_json, #self.parsing_attrs_json,
          :run_parents_json => "[]", #{"run_id" => matrix.run_id,"type" => "dataset","output_attr_name" => "output_matrix","input_attr_name" => "input_matrix"}].to_json,
#          :h_annots => {meta.id => meta, matrix.id => matrix},
          :output_json => "{}", #h_outputs.to_json,
          :lineage_run_ids => '{}', #lineage_run_ids.join(","),
          :submitted_at => Time.now
        }
        logger.debug("H_RUN => #{h_run.to_json}")
        #        h_cmd = {
        #          :program => "java -jar lib/ASAP.jar", # "rails parse[#{self.key}]",  #(mem > 10) ? "java -Xms#{mem}g -Xmx#{mem}g -jar /srv/ASAP.jar#" : 'java -jar /srv/ASAP.jar',        
        #          :opts => [
        #                    {"opt" => "-T", "value" => "CreateCellSelection"},
        #                    {"opt" => "-loom", "param_key" => "loom_filename", "value" => project_dir + loom_file},
        #                    #                  {"opt" => "-o", "value" => run_dir},                 
        #                    {"opt" => "-meta", "param_key" => 'annot_name', "value" => annot_name},
        #                    {"opt" => '-f', "value" => cell_indexes_filename}
        #                  ],
        #        :args => []
        #     }
        
        if find_marker_step and std_method

          run = Run.where({:project_id => project.id,
                            :step_id => find_marker_step.id,
                            :std_method_id => std_method.id,
                            :attrs_json => h_attrs.to_json
                          }).first
          if run
            run.update_attributes(h_run)
          else
            run = Run.new(h_run)
            logger.debug("H_RUN2 => #{h_run.to_json}")
            run.save
            logger.debug("created RUN:" + run.to_json)
          end
          output_dir = project_dir + find_marker_step.name 
          Dir.mkdir output_dir if !File.exist? output_dir
          output_dir = project_dir + find_marker_step.name + run.id.to_s
          if File.exist? output_dir
            FileUtils.rm_r output_dir
          end
          Dir.mkdir output_dir

#          
#          # set command
#
#          host_name =  h_cmd_params['host_name'] || 'localhost'
#          container_name = APP_CONFIG[:asap_instance_name] + "_" + run.id.to_s
#          
#          h_env_docker_image =h_env['docker_images'][docker_image]
#          image_name = h_env_docker_image['name'] + ":" + h_env_docker_image['tag']
#
#          h_cmd = {
#            :host_name => host_name,
#            :container_name => container_name,
#            :docker_call => (docker_image) ? h_env_docker_image['call'].gsub(/\#image_name/, image_name) : nil,
#            :time_call => h_env['time_call'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },
#            :exec_stdout => h_env['exec_stdout'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },
#            :exec_stderr => h_env['exec_stderr'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },            
#            :program => h_cmd_params[:program],
#            :opts => [
#                      {"opt" => "--loom", "param_key" => "loom_filename", "value" => matrix.filepath},
#                      {"opt" => "--iAnnot", "param_key" => 'annot_name', "value" => meta.name},
#                      {"opt" => '-o', "value" => output_dir + 'output.json'},
#                      {"opt" => '--id', "value" => meta.id }
#                     ]
#            #          :input_matrix => {:annot_id => parsing_matrix.id, :run_id => parsing_matrix.run_id, :output_filename => parsing_matrix.filepath},                                                                                                                                   #    
#            #          :annot_id => meta.id                                                                                                  #    
#          }
#          
#          h_upd = {
#            :command_json => h_cmd.to_json,    
#            :status_id => 1   
#          }
#          #          run.update_attributes({
#          #                                  :command_json => h_cmd.to_json,
#          #                                  :status_id => 1
#          #                                })
#          Basic.upd_run project, run, h_upd, true

          # set run
          
          h_run_attrs = JSON.parse(run.attrs_json)
          h_res = Basic.get_std_method_attrs(std_method, find_marker_step)
          h_attrs = h_res[:h_attrs]
          #    @h_global_params = h_res[:h_global_params]
          
          h_p = {
            :project => project,
            :h_cmd_params => h_cmd_params,
            :run => run,
            :p => h_run_attrs, #list_of_runs2[run_i][1],
            :h_attrs => h_attrs,
            :step => find_marker_step,
            :h_data_classes => h_data_classes,
            :std_method => std_method,
            :h_env => h_env,
            :h_annots => {meta.id => meta, matrix.id => matrix},
            :el_time => t,
            :user_id => user_id #(current_user) ? current_user.id : 1
          }
          h_res = Basic.set_run(logger, h_p)
          #          #          if !h_res[:error]
          #          #
          #          #            run.update_attributes({
          #          #                                    :status_id => 1                                   
          #          #                                  })
          #          #          
          #          #          end

          ### need to add the children
          children_runs = JSON.parse(matrix_run.children_run_ids)
          children_runs.push run.id if !children_runs.include? run.id
          matrix_run.update_attribute(:children_run_ids, children_runs.to_json)
          
        end
      end

      return {:run => run}

    end
    
    def recursive_parse_hca list_fields, h_data, h_cur, h_project_sum_matrices
      
      #   while (list_fields.include? k) do                                                                                                                                                                                    
      
      if h_data.is_a? Hash
        k = h_data.keys.first
        if h_data[k] and list_fields.include? k
          h_data[k].keys.each do |v|
            h_cur[k] = v
            recursive_parse_hca list_fields, h_data[k][v], h_cur, h_project_sum_matrices
          end
        end
      elsif h_data.is_a? Array
        h_data.each do |f|
          if f['format'] == 'loom'
            if ! h_project_sum_matrices[f['uuid']]
              h_project_sum_matrices[f['uuid']] = {
                :name => f['name'],
                :species => [h_cur['genusSpecies']],
                :organs => [h_cur['organ']],
                :development_stages => [h_cur['developmentStage']],
                :approaches => [h_cur['libraryConstructionApproach']],
                :url => f['url']
              }
            else
              l = [[:species, 'genusSpecies'],
                   [:organs, 'organ'],
                   [:development_stages, 'developmentStage'],
                   [:approaches, 'libraryConstructionApproach']]
              l.each do |e|
                h_project_sum_matrices[f['uuid']][e[0]].push h_cur[e[1]] if !h_project_sum_matrices[f['uuid']][e[0]].include? h_cur[e[1]]
              end
            end
          end
        end
      end
      
      return {
        #:h_data => h_data                                                                                                                                                                                                     
        :h_project_sum_matrices => h_project_sum_matrices
      }
    end

    def move_to_parent_dir source_dir
    
      parent_directory = File.expand_path('..', source_dir)
      # Use FileUtils.mv to move the contents
      FileUtils.mv(Dir.glob(File.join(source_dir, '*')), parent_directory)
      
      # Now, you can remove the empty source directory if needed
      FileUtils.rmdir(source_dir)
      
    end

    def convert_other_formats file_path, logger
      
      init_file_path = file_path
      logger.debug("INIT_PATH:" + file_path.to_s)
      base_dir = file_path.parent()
      tmp_file_path = base_dir + 'input_file'
      input_dir = base_dir + 'input_files'
      if File.exist? input_dir
        FileUtils.rm_r input_dir
      end
      #`cp #{file_path} #{tmp_file_path}` 
      FileUtils.cp file_path, tmp_file_path
      f_out = File.open("log/toto", 'a')
      logger.debug("CONVERT_TO_MTX")
      f_out.write('CONVERT_TO_MTX')
      ## check if the file is a zip or tar.gz file
      # cmd = "unzip"
      z_file_path = base_dir + 'input_file.gz'
      `mv #{tmp_file_path} #{z_file_path}`
      cmd = "gunzip #{z_file_path}"
      `#{cmd}`
      if !File.exist? tmp_file_path
        `mv #{z_file_path} #{tmp_file_path}`
        #if File.exist?(file_path)                                                                                                                           
        z_file_path = base_dir + 'input_file.bz2'
        `mv #{tmp_file_path} #{z_file_path}`
        cmd = "bunzip2 #{z_file_path}"
        `#{cmd}`
        if !File.exist? tmp_file_path
          `mv #{z_file_path} #{tmp_file_path}`
          Dir.mkdir input_dir
          z_file_path = input_dir + 'input_file.zip'
          `cp #{tmp_file_path} #{z_file_path}`
          Dir.chdir(input_dir) do
            cmd = "unzip input_file.zip"
            `#{cmd}`
          end
          ### check if there are some other files in the directory                                                                                                                                                        
          logger.debug("input_dir! " + input_dir.to_s)
          files = Dir.entries(input_dir).select{|e| e != "input_file.zip" and !e.match(/^\./)}
          if files.size == 0
            File.delete z_file_path
            logger.debug("move #{z_file_path.to_s} #{tmp_file_path.to_s}")
            Dir.rmdir(input_dir)
          else
            File.delete z_file_path
          end
        end
      end
      
      ## try to untar
      if !File.exist? input_dir
        Dir.mkdir input_dir
        `cp #{tmp_file_path} #{input_dir + 'input_file.tar'}`
        Dir.chdir input_dir do
          `tar -xvf #{tmp_file_path}`
        end
      end
      
      
      
      dirs = Dir.entries(input_dir).select{|e| f = input_dir + e; File.directory?(f) and !e.match(/^\./)}
      files = Dir.entries(input_dir).select{|e| f = input_dir + e; !File.directory?(f) and !e.match(/^\./)}
      logger.debug("DIR: " + dirs.to_json)
      logger.debug("FILES2:" + files.to_json)
      mtx_files = files.select{|e| e.match(/\.mtx$/)} 
      
      ## deal with the case of 1 sub-folder (https://cf.10xgenomics.com/samples/cell/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz)
      if files.size == 1 and dirs.size == 1
        d = dirs.first
        sub_dirs = Dir.entries(input_dir + d).select{|e| f = input_dir + d + e; File.directory?(f) and !e.match(/^\./)}
        sub_files =  Dir.entries(input_dir + d).select{|e| f = input_dir + d + e; !File.directory?(f)}
        logger.debug("DIR2: " + dirs.to_json)
        if sub_files.size == 0 and sub_dirs.size == 1
          logger.debug("DIR3: " + sub_dirs.to_json)
          #          FileUtils.mv input_dir + d + sub_dirs.first, input_dir + d 
          move_to_parent_dir(input_dir + d + sub_dirs.first)
        end
      end
      
      logger.debug("files:" + files.size.to_s + ", mtx_files: " + mtx_files.to_json)
      
      if files.size > 2 and (mtx_files.size == 1 or files.include?("matrix.mtx"))
        File.delete tmp_file_path
        File.delete input_dir + "input_file.tar" if File.exist?(input_dir + "input_file.tar")
        #           File.delete input_dir + "input_file.zip" if File.exist?(input_dir + "input_file.zip")                                                                                    
        logger.debug("cTEST1"  +  files.to_json)
      elsif dirs.size >0 #and files.size == 0
        dirs.each do |d|
          if Dir.entries(input_dir + d).select{|e| e.match(/\.mtx$/)}.size == 1 or Dir.entries(input_dir + d).include?("matrix.mtx")
            logger.debug("cTEST2: " + [input_dir + d, input_dir].to_json)
            Dir.entries(input_dir + d).select{|e| f = input_dir + d + e; !File.directory?(f) and !e.match(/^\./)}.each do |f|
              FileUtils.move input_dir + d + f, input_dir
            end
            Dir.rmdir input_dir + d
            #`mv #{(input_dir + d).to_s}/* #{input_dir}`
            logger.debug("cTEST2")
          end
        end
        
        
        
        # elsif files.size == 1
        #   FileUtils.move input_dir + files.first, tmp_file_path
        #   FileUtils.rm_r input_dir if File.exist? input_dir
        #   logger.debug("cTEST3")
        # else
        #   File.delete input_dir + "input_file.tar" if File.exist?(input_dir + "input_file.tar")
        #   FileUtils.rm_r input_dir if File.exist? input_dir
        #   #              Dir.rmdir input_dir if File.exist? input_dir       
        #   logger.debug("cTEST4")                   
      end
      
      ### if input_dir exists then apply the conversion
      h5_file_path = base_dir + 'input.h5'
      
      ## rename mtx file if only one
      mtx_files = Dir.entries(input_dir).select{|e| e.match(/\.mtx$/)}
      
      if mtx_files.size == 1
        if !File.exist? input_dir + 'matrix.mtx'
          FileUtils.mv input_dir + mtx_files.first, input_dir + 'matrix.mtx'
        end
      end
      
      if File.exist? input_dir and File.exist? input_dir + 'matrix.mtx'     
        cmd = "#{APP_CONFIG[:docker_call]} 'Rscript --vanilla /srv/mtx_to_h5.R #{input_dir} #{h5_file_path}'"
        logger.debug("CMD_CONVERT:" + cmd)
        f_out.write("CMD_CONVERT:" + cmd)
        `#{cmd}`
        if File.exist? h5_file_path and File.size(h5_file_path) > 0
          file_path = h5_file_path
          type = 'MEX'
        end
      end
      
      f_out.close

      logger.debug("#{init_file_path} == #{file_path}")
      
      if init_file_path == file_path
     
        ## check if it's a rds file
        if file_path.to_s.match(/\.rds$/)
          ##try to convert
          logger.debug("TRY RDS CONVERSION")
          loom_file_path = base_dir + 'input.loom'
#          cmd = "#{APP_CONFIG[:docker_call]} \"Rscript -e \\\"rmarkdown::render('convert_seurat.Rmd', params = list(input=\'#{file_path.to_s}\', output=\'#{loom_file_path}\'))\\\"\""
          docker_call_v7 = "docker run --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v7 -c"
          cmd = "#{docker_call_v7} 'Rscript --vanilla /srv/convert_seurat.R #{file_path.to_s} #{loom_file_path}'"
          logger.debug("CMD RDS: #{cmd}")
          `#{cmd}`
          if File.exist? loom_file_path
            file_path = loom_file_path
            type = 'RDS'
          end
        end
        
      end
      
      logger.debug("FINAL_PATH:" + file_path.to_s)
      return {:file_path => file_path, :type => type}
    end

     def sql_query3 version, model, select, where

      h = {
        :model => model,
        :select => select,
        :where => where
      }

      cmd = "RAILS_ENV=data_v#{versiom.to_s} && echo '#{t.to_json}' | rails -q get_data"
      res = `#{cmd}`
      res.split("\n").each do
      end
      return
    end

    
    def sql_query2 type, version, from, join, select, where
      require 'ostruct'
      version ||= ''

      where||='1=1'
      #      query = model.select(select).joins(join).where(where).to_sql.gsub("'", "\\\\'")
      query = "select #{select} from #{from} #{join} where #{where}" #.gsub("'", "\\\\'")
#      puts query
      h_cmd = {
        :asap_development => "psql -h postgres -p 5434 -U postgres -AF $'<\t>' --no-align -c \"#{query}\" asap2_development",
        :asap_data => "psql -h postgres -p 5434 -U postgres -AF $'<\t>' --no-align -c \"#{query}\" asap2_data_v#{version}"
      }
      
 
      cmd = h_cmd[type]
      output = `#{cmd}`
      res = []
      headers = []
      flag = 0
      t = output.split("\n")
        (0 .. t.size-2).each do |i|        
        if i == 0
          t[i].split("<\t>").each do |e|
            headers.push e
          end
        else
          h_data = {}
          t2 = t[i].split("<\t>")
          t2.each_index do |j|
            h_data[headers[j]] = t2[j]
          end
          res.push OpenStruct.new(h_data)
        end
      end
      return res 
    end      
    
    def sql_query shard, model, select, where
      
      res = nil
      
      begin
        
        # Get the hash (i.e. parsed) representation of database.yml
        databases = Rails.configuration.database_configuration
        
        # Get a fancier AR-specific version of this hash, which is actually a wrapper of the hash
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(databases)
        
        # Get one specific database from our list of databases in database.yml. pick any database identifier (:development, :user_shard1, etc)
        spec = resolver.spec(shard)

        # Make a new pool for the database we picked
        pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
        
        # Use the pool
        # This is thread-safe, ie unlike ActiveRecord's establish_connection, it won't leak to other threads
        pool.with_connection { |conn|
          
          # Now we can perform direct SQL commands
         # result = conn.execute('select count(*) from users') # result will be an array of rows
         # puts result.first
          
          # We can make AR queries using to_sql
          # See http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html
          sql = model.select(select).where(where).to_sql # generate SQL string
          res = conn.select_all sql # get list of hashes, one hash per matching result
          
        }
        
      rescue => ex
        puts ex, ex.backtrace
      ensure
        pool.disconnect!
      end
      
      return res
    end
    
    
    def set_predict_params p, run, std_method, h_runs, h_steps
      
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
      
      h_predict_params = {}
      
      if run.std_method_id #and run.std_method_id == 25                                                                                                            
        puts "RUN: #{run.id}"
        h_command = Basic.safe_parse_json(std_method.command_json, {})
        h_attrs = {}
        h_run_attrs = Basic.safe_parse_json(run.attrs_json, {})
        puts h_run_attrs.to_json
        if h_command['predict_params']
          h_command['predict_params'].select{|e| e != 'std_method_name' and h_run_attrs[e]}.each do |e|
            h_predict_params[e] = h_run_attrs[e]
          end
        end
        
        #puts h_run_attrs.to_json                                                                                                                                  
        #{"input_matrix":{"run_id":14078,"output_attr_name":"output_matrix","output_filename":"cell_filtering/14078/output.loom","output_dataset":"/matrix"},"fdr":"0.1","min_disp":"0.5"}                                                                  
        input_matrix_run = nil
        ['input_matrix', 'input_de'].each do |e|
          puts "H_RUN_ATTRS:" + h_run_attrs.to_json
          if h_run_attrs[e] and  input_matrix = ((h_run_attrs[e].is_a? Array) ? h_run_attrs[e][0] : h_run_attrs[e]) and input_matrix['run_id']
            puts input_matrix.to_json
            input_matrix_run = h_runs[input_matrix["run_id"].to_i]
          end
        end

        puts "H_STEPS: " + h_steps.to_json
        if h_steps[run.step_id].name != 'parsing'
          #   h_attrs['nber_cols'] = p.nber_cols.to_i
          #   h_attrs['nber_rows'] = p.nber_rows.to_i
          # else
          
#          input_matrix_run = nil
#          ['input_matrix', 'input_de'].each do |e|
#          input_matrix_run = h_runs[h_run_attrs[e]["run_id"].to_i] if h_run_attrs[e] and h_run_attrs[e]["run_id"]
#          end
                    
          if input_matrix_run
            run_dir = project_dir + h_steps[input_matrix_run.step_id].name
            run_dir += input_matrix_run.id.to_s if h_steps[input_matrix_run.step_id].multiple_runs == true #) ? (local_step_dir + a.run_id.to_s) : local_step_dir)  
            output_file = run_dir + 'output.json'
            h_tmp = {}
            if File.exist? output_file
              h_tmp = Basic.safe_parse_json(File.read(output_file), {})
            end
            
            h_tmp.each_key do |k|
              h_attrs[k] = h_tmp[k]
            end
            
            ['nber_cols', 'nber_rows'].each do |k|
              if !h_attrs[k] and h_attrs['metadata']
                if h_attrs['metadata'][0]
                  h_attrs[k] =h_attrs['metadata'][0][k].to_i
                else
                  puts h_attrs['metadata'].to_json
                end
              end
            end
            
          end
        end
        
        if h_command['predict_params']
          h_command['predict_params'].reject{|e| e == 'std_method_name'}.each do |e|
            h_predict_params[e] = h_attrs[e] if h_attrs[e]
          end
        end
      end
      return h_predict_params
      
    end
    
    def get_run_stats version
      asap_docker_image = get_asap_docker(version)
      h_run_stats = {}
      #project_ids = Project.select("id").where(:version_id => version.id).all
      
      #      StdMethod.where(:version_id => version.id).all.each do |s|
      StdMethod.where(:docker_image_id => asap_docker_image.id
                      ).all.each do |s| 
        h_run_stats[s.id] = {
          :pred_params => Basic.safe_parse_json(s.command_json, {})['predict_params'],
          :std_method_name => s.name,
          :runs => []
        }
      end
      
      all_runs = Run.joins(:project).where(:projects => {:version_id => version}, :std_method_id => h_run_stats.keys).all.reject{|r| r.process_duration == 0} + #and [1, 20].include?(r.step_id)} +
        DelRun.joins(:project).where(:projects => {:version_id => version}, :std_method_id => h_run_stats.keys).all.reject{|r| r.process_duration == 0}# and [1, 20].include?(r.step_id)}
      
      all_runs.each do |r|
        if h_run_stats[r.std_method_id]
          #          puts r.to_json
          #          exit
          # h_run_stats[r.std_method_id] ||= {:runs => [], :predict_params => }                                                                                   
          h_tmp = {:id => r.id, :t => r.process_duration, :m => r.max_ram, :c => r.nber_cores || 1}
          h_predict_params = Basic.safe_parse_json(r.pred_params_json, {})
          if  h_predict_params.keys.size > 0
            h_predict_params.each_key do |k|
              h_tmp[k] = (['nber_cols', 'nber_rows'].include? k) ?  h_predict_params[k].to_i : h_predict_params[k]
            end
            if h_tmp['nber_cols'] and h_tmp['nber_rows'] and h_tmp['nber_cols'] != 0 and h_tmp['nber_rows'] != 0
              h_run_stats[r.std_method_id][:runs].push(h_tmp)
            end
          end
        end
      end
      
      list = []
      h_run_stats.each_key do |sid|
        h_tmp =  h_run_stats[sid]
        h_tmp[:std_method_id] = sid
        list.push h_tmp
      end
      
      return list
    end

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

    def unarchive k
      h_s3_settings = get_s3_settings()
      s3b = {
        :key => '20000-af8a16d143d9920a26869b30700c3da4',
        :endpoint => 'https://s3.epfl.ch',
        :region => 'us-west-2'
      }
      s3 = connect_s3 s3b, h_s3_settings
      
      p = Project.find_by_key(k)
      if p
        p.update_attributes({:archive_status_id => 4})
        project_archive = p.key + '.tgz'
        user_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s
        filepath = user_dir + project_archive

        ## get file from s3
        if !File.exist? filepath
          
          r = write_file_from_s3 s3, s3b[:key], p, filepath
          while r == false and !File.exist? filepath
            sleep 2
            r = write_file_from_s3 s3, s3b[:key], p, filepath
          end
        end
        
        ## tar and pigz
        cmd = "cd #{user_dir} && pigz -p 32 -dc #{project_archive} | tar -xv"
        puts "CMD: #{cmd}"
        `#{cmd}`
        ## delete archive
        if File.exist? user_dir + p.key and `du -s #{user_dir + p.key}`.to_i > 10 #and `du -s #{user_dir + p.key}`.to_i == p.disk_size ### IDEALLY should uncomment
          File.delete user_dir + project_archive
        end
        p.update_attributes(:archive_status_id => 1, :disk_size_archived => nil)
      end
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
    #  puts h_attrs.to_json
     # puts h_global_params.to_json
      h_global_params.each_key do |k|
     #   puts "->k: #{k}"
        puts h_attrs.to_json
       #flag = 0
       # if !h_attrs[k]
#       #   puts "#{std_method.id}-> k #{k} OK"
        #else
        #  flag = 1
       #   puts "#{std_method.id}-> k #{k} already exist (not changed): #{h_attrs[k].to_json} => #{h_global_params[k].to_json}!!!!!!!!!!!!!!!!!!!"
       # end
        h_attrs[k]={} if !h_attrs[k]
        h_global_params[k].each_key do |k2|
     #     puts "->k2: #{k2}, #{h_global_params[k][k2]}"
          h_attrs[k][k2] = h_global_params[k][k2] if ! h_attrs[k][k2] 
        end
        
       # if flag== 1
       #   puts "!!!!!!!!!!!!!!Result =>" + h_attrs[k].to_json
       # end
        
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

    def  add_cell_sets p, project_dir, a, meta_compl, list_cats
      h_cell_sets = {}
      h_cell_set_by_cat_idx = {}
      pc = p.project_cell_set
      cell_ids_file = project_dir + 'parsing' + 'cell_ids'
      stable_ids_file = project_dir + (a.filepath + ".stable_ids")
      if !pc
        puts "ERROR! Project #{p.id} has no project_cell_set associated to it"
        project_cell_set = ProjectCellSet.where(:id => p.project_cell_set_id).first
        puts "PROJECT: " + p.to_json
        puts "PROJECT2: " + Project.where(:key => p.key).first.to_json
        puts "PROJECT_CELL_SET: " + project_cell_set.to_json
      elsif File.exist?(stable_ids_file) and File.exist?(cell_ids_file)

        output = File.read(cell_ids_file)
        res =  Basic.safe_parse_json(output,  {})
        cells = res['values']

        output = File.read(stable_ids_file)
        res = Basic.safe_parse_json(output,  {})
        stable_ids = res['values']

        vals = meta_compl['values']
        
        if vals and cells and cells.size > 0 and stable_ids
          if vals.size == stable_ids.size

            ## init annot cell sets

            h_annot_cell_sets = {}
            AnnotCellSet.where(:project_id => p.id).all.each do |acs|
              h_annot_cell_sets[[acs.annot_id, acs.cat_idx]] = acs
            end
            
            h_cells = {}

            ## init categories                                                                                                                                  
            list_cats.each do |cat|
              h_cells[cat] = []
            end
            vals.each_index do |i|
              #    puts vals[i]                                                                                                                                 
              if h_cells[vals[i]] and stable_ids[i]
                h_cells[vals[i]].push cells[stable_ids[i]]
              else
                puts "Category #{vals[i]} not found in #{a.name} [#{project_dir + a.filepath}]."
              end
            end
            ## for each category compute hash                                                                                                                   
            #     list_md5 = []                                                                                                                                 
            list_cats.each_index do |cat_idx|
              cat = list_cats[cat_idx]
              # list_md5.push Digest::MD5.hexdigest h_cells[cat].to_json                                                                                        
              md5 = Digest::MD5.hexdigest h_cells[cat].sort.to_json
              
              h_cell_set = {
                :key => md5,
                :project_cell_set_id => pc.id,
                :nber_cells => h_cells[cat].size
              }
              
              #            cell_set = CellSet.where(:key => md5, :project_cell_set_id => pc.id).first                                                           
              cell_set = h_cell_sets[md5]
              if !cell_set
                cell_set = CellSet.new(h_cell_set)
                cell_set.save
                h_cell_sets[md5] = cell_set
                puts "Create cell set #{cell_set.id}"
              else
                puts "cell set #{cell_set.id} exists!"
              end
              h_cell_set_by_cat_idx[cat_idx] = cell_set
              
              h_ac = {
                # :cell_set_id => cell_set.id,                                                                                                             
                :project_id => p.id,
                :annot_id => a.id,
                :cat_idx => cat_idx
              }
              #    ac = AnnotCellSet.where(h_ac).first                                                                                                         
              ac = h_annot_cell_sets[[a.id, cat_idx]]
              if !ac
                h_ac[:cell_set_id] = cell_set.id
                ac = AnnotCellSet.new(h_ac)
                ac.save
                h_annot_cell_sets[[a.id, cat_idx]] = ac
                puts "Create annot_cell_set #{ac.id}"
                # elsif ac.cell_set_id != cell_set                                                                                                              
                #   ac.update_attributes({:cell_set_id => cell_set.id})                                                                                         
                #   h_annot_cell_sets[[h_a[:annot].id, cat_idx]]= ac                                                                                            
                # puts "Update annot_cell_set #{ac.id}"                                                                                                         
              else
                puts "annot_cell_set #{ac.id} exists!"
              end
              
            end
          else
            puts "Stable IDs and metadata have not same sizes (#{stable_ids.size} vs. #{vals.size})"
          end
        else
          puts "Vals (#{vals.to_json}) or cells not there"
        end
      end
      
      return h_cell_set_by_cat_idx
    end

    def add_clas project, a, h_cell_sets

   #   user = User.where(:id => a.user_id).first
   #   orcid_user = user.orcid_user #OrcidUser.where(:user_id => a.user_id).first
      list_cats =  Basic.safe_parse_json(a.list_cat_json, [])
      h_cat_aliases = Basic.safe_parse_json(a.cat_aliases_json, {})
      sel_clas = []
      list_cats.each_index do |i|
        k = list_cats[i]
#        annot_name = h_cat_aliases['names'][k] #if h_cat_aliases['names'][k] != k
#        if ! annot_name
        annot_name = k
#        end
        if annot_name and annot_name != ''
          
          cot = CellOntologyTerm.where(["(identifier = ? or name = ?) and original = true", annot_name, annot_name]).first
          cot_ids = (cot) ? cot.id : nil
          h_cla = {
            :cla_source_id => 3,
            :name => (cot) ? "" : annot_name, # : 1,
            :annot_id => a.id,
            :num => 1,
            :cat_idx => i,
            :cell_set_id => (h_cell_sets[i]) ? h_cell_sets[i].id : nil,
            :cell_ontology_term_ids => cot_ids,
            :cat => k, #a.name, #(cot) ? '' : k,
            :user_id => a.user_id, #(h_cat_aliases and h_cat_aliases['user_ids'] and h_cat_aliases['user_ids'][k]) ? h_cat_aliases['user_ids'][k] : a.user_id,
          #  :orcid_user_id => (orcid_user) ? orcid_user.id : nil, 
            :project_id => a.project_id
          }
          
          h_cla2 = {
            :cell_set_id => (h_cell_sets[i]) ? h_cell_sets[i].id : nil,
            :cell_ontology_term_ids => cot_ids,
            :name => (cot) ? "" : annot_name
          }

          cla = Cla.where(h_cla2).first
          if !cla
            cla = Cla.new(h_cla)
            cla.save
          end
          sel_clas.push cla.id

          ## add vote
          #          h_cla_vote = {
          #            :cla_source_id => 3, #(p.name.match(/HCA/)) ? 3 : ((p.name.match(/FCA/)) ? 2 : 1),
          #            :cla_id => cla.id,
          #            :user_name => (user.id == 1) ? 'admin' : user.displayed_name, #user.email.split(/@/).first,
          #            :user_id => user.id,
          #            :orcid_user_id => (orcid_user) ? orcid_user.id : nil,
          #            :comment => '',
          #            :agree => true
          #          }
          #
          #          cla_vote = ClaVote.where(h_cla_vote).first
          #          if !cla_vote
          #            cla_vote = ClaVote.new(h_cla_vote)
          #            cla_vote.save
          #          end
          #
          #          ## update nber_votes                                                                                                    
          #          cla.update_attributes({:nber_agree => 1})
          
        else
          sel_clas.push ""
        end
      end
      
      h_cla_sum = {
        :nber_clas => (0 .. list_cats.size-1).to_a.map{|i| (sel_clas[i] == '') ? 0 : 1},
        :selected_cla_ids => sel_clas
      }
      
      a.update_attributes({:cat_info_json => h_cla_sum.to_json})

    end
    
    def load_annot run, meta, relative_filepath, h_data_types, h_data_classes, logger
      
      #list_metadata.each do |meta|
      project = Project.where(:id => run.project_id).first #run.project
      puts run.project.to_json
      puts "project => #{project.to_json}"

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    
      puts "BLAAAA: " + meta.to_json
      
      puts "h_data_types: " + h_data_types.to_json
      
      #      if annot = Annot.where(:project_id => run.project_id, :name => meta['name'], :run_id => run.id).first
      #        annot.destroy          
      #      end
      
      #      annot_path = meta['name']
      #      t =  meta['name'].split("/")
      #      annot_name = meta['name'].gsub(/(\/.{3}_attrs\/)/, '')

      #      relative_filepath = relative_path(project, filepath)

      # create or update fo
      fo = create_upd_fo(run.project_id, relative_filepath)
      annot = Annot.where(:name => meta['name'], :filepath => relative_filepath, :store_run_id => (fo) ? fo.run_id : nil, :project_id => run.project_id).first
      
      # complete annotation details if data type is not defined      
      #      if !meta['type'] or !meta['dataset_size']
      ## get same annotation from parsing
      ori_annot = Annot.where(:project_id => project.id, :name => meta['name']).order("id asc").first
      type_txt = ''
      puts "ANNOT : " + annot.to_json
      puts "ORI_ANNOT : " + ori_annot.to_json
      if ori_annot and annot != ori_annot ## second part of expression: in case of re-importing a metadata or creating again the same metadata, do not get the metadata attributes from the previous metadata version (it might be outdated, for example in the case of imported metadata => the type can me changed by the user)
        meta["type"] = (dt = ori_annot.data_type) ? dt.name : nil
        meta["data_class_names"] = ori_annot.data_class_ids.split(",").map{|e| h_data_classes[e.to_i].name} 
        meta["imported"] = ori_annot.imported
        type_txt = (dt = ori_annot.data_type) ? "-type #{dt.name}" : ""
      end
      type_txt = "-type #{h_data_types[meta['forced_type_id']].name}"  if meta['forced_type_id']
      
      loom_path = project_dir + relative_filepath
      puts "META: " + meta.to_json
      if meta['data_class_names'] and meta['data_class_names'].include?("discrete_mdata")
        meta["type"]= 'DISCRETE'
      end
      values_opt = (meta["type"] == 'DISCRETE') ? '' : '-no-values' 
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar #{values_opt} -T ExtractMetadata -loom #{loom_path} #{type_txt} -meta \"#{meta['name']}\""
      puts cmd
      res_json =`#{cmd}`
      #   puts res_json
      meta_compl = Basic.safe_parse_json(res_json, {})
      puts meta_compl
      #        begin
      #          meta_compl = JSON.parse(res_json)
      #        rescue
      #        end

      ## complement for h5ad existing_metadata or if we want to change type (call from annot update)
      ['type', 'on', 'nber_rows', 'nber_cols', 'dataset_size'].each do |k|
        meta[k] ||= meta_compl[k] 
      end

      ## override certain parameters
      list_p = ['nber_cols', 'nber_rows', 'dataset_size']
      list_p.push("categories") if meta["type"] == 'DISCRETE'
      list_p.each do |k|
        meta[k] = meta_compl[k] if meta_compl[k]
      end

      data_class_names = meta['data_class_names'] || []
      puts "DATA_CLASS_NAMES: " + data_class_names.to_json
      
      ### if imported data, try to guess types
      #if data_class_names.size == 0 #meta['imported'] == true
      if meta['imported'] == true or meta['forced_type_id'] #or data_class_names.size == 0
        #data_class_names |= ['dataset'] #, h_on[meta['on']]]
        if meta['name'].match(/^\/layers\//)
          data_class_names |= ['dataset', 'matrix', 'num_matrix']
        elsif meta['name'].match(/^\/col_attrs\//)
          data_class_names |= ['dataset', 'mdata', 'col_mdata']
        elsif meta['name'].match(/^\/row_attrs\//)
          data_class_names |= ['dataset', 'mdata', 'row_mdata']
            #        elsif meta['name'].match(/^\/row_attrs\//)
        elsif meta['name'].match(/^\/attrs\//)
          data_class_names |= ['global_mdata']
        end
        data_class_names |= ["#{meta["type"].downcase}_mdata"] if meta["type"]
        if meta['on'] == 'EXPRESSION_MATRIX' # meta['nber_cols'] > 1 and meta['nber_rows'] > 1 and meta["type"] == 'NUMERIC'
          data_class_names |= ['matrix', 'num_matrix']
        end
      end
      
      data_classes = []
      data_class_names.each do |data_class_name|
        if !data_class = h_data_classes[data_class_name] and !data_class = DataClass.where(:name => data_class_name).first
          data_class = DataClass.new(:name => data_class_name)
          data_class.save
          h_data_classes[data_class_name]= data_class
        end
        data_classes.push h_data_classes[data_class_name]
      end
      puts "DATA_CLASSES: " + data_classes.to_json

      output_attr = nil
      if meta['output_attr_name']
        output_attr = OutputAttr.where(:name => meta['output_attr_name']).first
        if !output_attr
          output_attr = OutputAttr.new(:name => meta['output_attr_name'])
          output_attr.save
        end
      end
      
      # meta.delete('data_class_names') if meta['data_class_names']
      
      h_meta_types = {
        'EXPRESSION_MATRIX' => 3,
        'GLOBAL' => 4,
        'CELL' => 1,
        'GENE' => 2
      }

      if !meta['headers']
        de_steps=Step.where(:name => 'de').all
        meta['headers'] = ["logFC", "P-value", "FDR", "Avg group1", "Avg group2"] if de_steps.map{|e| e.id}.include? run.step_id
      end

      ori_annot2 = nil

      if meta['name'] != '/matrix'
        ori_annot2 = Annot.where(:project_id => project.id, :name => meta['name']).order('id').first
      end
      
      allow = true

      ## do not propagate de results     
      allow = false if fo.run_id == run.id and meta['on'] == 'GENE' and meta['name'].match(/_de_\d+/) and meta['imported'] == false

      puts "Allowed? : " + allow.to_json

      if allow

        list_cats = nil
        if meta['categories']
          nber_int = meta['categories'].keys.select{|k| k.match(/^-?\d+$/)}.size
          nber_float = meta['categories'].keys.select{|k| k.match(/^-?\d*\.?\d+?$/)}.size
          if nber_int == meta['categories'].keys.size
            list_cats = meta['categories'].keys.map{|e| [e.to_i, e]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}
          elsif  nber_float == meta['categories'].keys.size
            list_cats = meta['categories'].keys.map{|e| [e.to_f,e]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}
          else
            list_cats = meta['categories'].keys.sort
          end
        end
        h_annot = {
          :project_id => run.project_id,
          :step_id => run.step_id,
          :run_id => run.id,
          :filepath => relative_filepath,
          :store_run_id => (fo) ? fo.run_id : nil,
          :ori_run_id => (ori_annot2) ? ori_annot2.run_id : run.id,
          :ori_step_id => (ori_annot2) ? ori_annot2.step_id : run.step_id,
          :headers_json => (meta['nber_rows'] and meta['nber_cols'] and meta['nber_rows'] > 0 and meta['nber_cols'] > 0 and meta['on'] != 'EXPRESSION_MATRIX') ? ((meta['headers']) ? meta['headers'].to_json : ((1 .. ((meta['on'] == 'GENE') ? meta['nber_cols'] : meta['nber_rows'])).map{|i| "Value #{i}"}.to_json)) : nil, 
          # :fo_id => (fo) ? fo.id : nil,
          :name => meta['name'],
          :categories_json => (meta['categories']) ? meta['categories'].to_json : nil,
          :list_cat_json => (list_cats) ? list_cats.to_json : nil, #(meta['categories']) ? meta['categories'].keys.sort.to_json : nil,
          :dim => (h_meta_types[meta['on']]) ? h_meta_types[meta['on']] : nil, #(meta['on'] == 'EXPRESSION_MATRIX') ? 3 : ((meta['on'] == 'CELL') ? 1 : 2),
          :data_type_id => (dt = h_data_types[meta['type']]) ? dt.id : nil,
          :nber_cats => (meta['categories']) ? meta['categories'].size : nil,
          :nber_rows => meta['nber_rows'],
          :nber_cols => meta['nber_cols'],
          :data_class_ids => data_classes.flatten.uniq.map{|e| e.id}.sort.join(","),
          :mem_size => meta['dataset_size'], # (meta['nber_cols'] and  meta['nber_rows']) ? 4 * meta['nber_cols'] * meta['nber_rows'] : nil,
          :label => nil,
          :imported => (meta['imported'] == true) ? true : false,
          :output_attr_id => (output_attr) ? output_attr.id : nil,
          :user_id => run.user_id
        }
        
#        annot = Annot.where(:name => meta['name'], :filepath => relative_filepath, :store_run_id => (fo) ? fo.run_id : nil, :project_id => run.project_id).first

        puts "test annot"
        if !annot
          annot = Annot.new(h_annot)
          annot.save!
        elsif !(h_annot[:data_class_ids] == '' and annot.data_class_ids != '')
          puts "H_ANNOT: " + h_annot.to_json
          annot.update_attributes(h_annot)
        end

        ## save list of stable_ids in file
        stable_ids_file = project_dir + (annot.filepath + ".stable_ids")
        if !File.exist? stable_ids_file #annot.store_run_id == annot.run_id and annot.dim == 3
          puts "get stable_ids for #{annot.filepath}..."
          cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + annot.filepath} -meta /col_attrs/_StableID"
       #   res = Basic.safe_parse_json(`#{cmd}`, {})
       #   stable_ids = res['values']
          File.open(stable_ids_file, "w") do |fout|
            fout.write(`#{cmd}`)
          end
        end
        
        ## add clas
        if annot.data_type_id == 3 and annot.dim == 1 
          puts "Test cell sets"
          h_cell_sets = add_cell_sets(project, project_dir, annot, meta_compl, list_cats)
          add_clas(project, annot, h_cell_sets)
        end
        
        ## compute_marker genes
        if project.user_id == 1 and project.sandbox == false
          
          #        cell_metadata = project.annots.select{|a| a.data_type_id ==3 and a.dim == 1}
          #        cell_metadata.each do |meta|
          if annot.data_type_id == 3 and annot.dim == 1
#            h_markers = Basic.find_markers(logger, project, annot, run.user_id)
#            h_marker_enrichment = Basic.find_marker_enrichment(logger, project, annot, h_markers[:run], run.user_id)
          end
        end
      end

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
      if File.exist? project_dir
        project.update_attributes(:disk_size => `du -s #{project_dir}`.split(/\s+/).first.to_i * 1000)
      else
        puts "Project directory does not exist. Current size in DB: #{project.disk_size}" 
      end
    end

    def upd_project_step project, step_id
      h_project_step = Basic.get_project_step_details(project, step_id)
      all_project_steps = ProjectStep.where(:project_id => project.id).all
      project_step = all_project_steps.select{|e| e.step_id == step_id}.first #ProjectStep.where(:project_id => project.id, :step_id => step_id).first
      if project_step
        project_step.update_attributes(h_project_step)
      end
      # puts "PROJECT_STEP: " + project_step.to_json
      ### update project stats
      h_steps = {}
      Step.all.map{|s| h_steps[s.id] = s}
      h_nber_runs = {}

      all_project_steps.select{|ps| h_steps[ps.step_id].hidden == false}.each do |ps|
        h_tmp = JSON.parse(ps.nber_runs_json)
        h_tmp.keys.map{|k| h_nber_runs[k]||=0; h_nber_runs[k] += h_tmp[k]}
      end
      # puts h_nber_runs.to_json
      h_upd = {:nber_runs_json => h_nber_runs.to_json}
      if h_steps[step_id].hidden == false ## do not change modified_at when executing hidden step runs
        h_upd[:modified_at] = Time.now 
      end
      project.update_attributes(h_upd)
    end

    def save_run run
      run.save
     # h_active_run = run.as_json
     # h_active_run[:run_id]= run.id
     # h_active_run.delete(:id)
     # active_run = ActiveRun.new(h_active_run)
     # active_run.save!
    end

    def upd_run project, run, h_upd, upd_project_step
    #  puts "PROBLEM_HERE"
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
      if  upd_project_step
        upd_project_step project, run.step_id
      end
      #end

    end

    def set_run logger, h_p

      h_res = {}

#      puts "Elapsed time 9a:" + (Time.now-h_p[:el_time]).to_s

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + h_p[:project].user_id.to_s + h_p[:project].key
      run = h_p[:run] #list_of_runs[run_i][0]
      p = h_p[:p] #list_of_runs[run_i][1]
 #     h_step_attrs = JSON.parse(run.step.attrs_json)
      logger.debug("SET_RUN")
      docker_image = h_p[:h_cmd_params]['docker_image']
     # step = run.step
      step_dir = project_dir + h_p[:step].name
      Dir.mkdir step_dir if !File.exist? step_dir
      output_dir = (h_p[:step].multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      Dir.mkdir output_dir if !File.exist? output_dir
      
      h_attrs = JSON.parse(h_p[:run].attrs_json)

#      version = h_p[:project].version
#      asap_docker_image = get_asap_docker(version)

#      Step.where(:docker_image_id => asap_docker_image.id).all.each do |s|
#        h_steps[s.id] = s
#      end
      
      h_var = {
        'user_id' => h_p[:run].user_id,
        'project_dir' => project_dir,        
        'output_dir' => output_dir, #project_dir + h_p[:step].name + run.id.to_s,
        'std_method_name' => h_p[:std_method].name,
        'step_tag' => h_p[:step].tag,
        'step_name' => h_p[:step].name,
        'run_num' => run.num,
        'asap_data_docker_db_conn' => 'postgres:5434/asap2_data_v' + h_p[:h_env]['asap_data_db_version'].to_s, #h_p[:project].version_id.to_s,
        'asap_data_direct_db_conn' => 'postgres:5433/asap2_data_v' + h_p[:h_env]['asap_data_db_version'].to_s #h_p[:project].version_id.to_s,
      }

 #      puts "Elapsed time 9b:" + (Time.now-h_p[:el_time]).to_s

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
      
  #    puts "Elapsed time 9c:" + (Time.now-h_p[:el_time]).to_s
      logger.debug("P_DEBUG:" + p.to_json)
      puts p.to_json
      p.each_key do |k|
        logger.debug("ATTR:" + k)
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
        logger.debug("ATTRS:" + h_p[:h_attrs].to_json)
        if h_p[:h_attrs][k.to_s] and h_p[:h_attrs][k.to_s]['valid_types']
          logger.debug("ATTR2:" + k)
          ### handle annotations (that are not considered as datasets - but can still be used as input)

          ### handle datasets
          
          if h_p[:h_attrs][k.to_s]['valid_types'].flatten.include?('dataset')
            logger.debug("ATTR3:" + k)
            list_datasets = []            
            if h_p[:h_attrs][k.to_s]['req_data_structure'] == 'array' and !h_p[:h_attrs][k.to_s]['combinatorial_runs'] and p[k] and !p[k].empty?
              ### cases where there are several items
              logger.debug("ATTR4:" + p[k].to_json)
              list_datasets = p[k]
              #              h_var[k]=[]
            else
             # logger.debug(h_p[:h_attrs][k.to_s]['req_data_structure'])
             # logger.debug()
              list_datasets = [p[k]]
            end
            
            tmp_var = [] 

            ## get all annots
            h_annots = h_p[:h_annots]
#            h_annots = {}
#            Annot.where(:id => list_datasets.map{|dt| dt['annot_id']}.uniq.compact).all.map{|a| h_annots[a.id] = a}

            list_datasets.each do |dt|
              logger.debug("DATASET_ITEM: #{dt.to_json}")
              linked_annot = nil
              if dt['annot_id']
                linked_annot = h_annots[dt['annot_id']]
              #  linked_run = linked_annot.run
                dt['output_filename'] = linked_annot.filepath
                dt['output_dataset'] = linked_annot.name
                dt['output_attr_name'] = (oa = linked_annot.output_attr) ? oa.name : nil
              end
              
              linked_run = Run.where(:id => dt['run_id']).first
              h_parent_runs[linked_run.id] = linked_run
              
              lineage_runs = Run.where(:id => linked_run.lineage_run_ids.split(",")).all
              norm_dataset = Annot.joins(:step).where(:run_id => lineage_runs, :steps => {:name => "normalization"}).first
              h_var['norm_matrix_dataset'] = norm_dataset.name  if norm_dataset              

              h_linked_run_outputs = nil
              if !linked_run
                h_res[:error] = 'Linked run was not found!'
              else
                h_linked_run_outputs = JSON.parse(linked_run.output_json)
             #   if h_linked_run_outputs['annot']
                output_key = ['output_filename', 'output_dataset'].map{|e| dt[e]}.compact.join(":")
                if h_linked_run_outputs[dt['output_attr_name']]
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
                  # else
                  end
                elsif linked_annot
                  
                  h_var[k + "_filename"] = project_dir + dt['output_filename']
                  h_var[k + "_dataset"] = dt['output_dataset']
                  h_var[k + "_run_id"] = dt['run_id']
                  h_var[k + "_is_count_table"] = (linked_annot["data_class_ids"].split(",").map{|e| h_p[:h_data_classes][e.to_i].name}.flatten.include?("int_matrix")) ? 'true' : 'false'
                else  
                  puts "Cannot find output with key #{(dt) ? dt['output_attr_name'] : 'NA'} #{linked_annot.to_json}!!!"
                end

                logger.debug("DATA_TMP:" + dt.to_json)
                logger.debug("LINKED_ANNOT:" + linked_annot.to_json)
                logger.debug("HVAR:" + h_var.to_json)
                if linked_annot and (['output_matrix', 'output_mdata'].include?(dt['output_attr_name']) or linked_annot.imported == true)
                #  ['nber_cols', 'nber_rows'].each do |v|
                  h_var['nber_cols'] = linked_annot.nber_cols if !h_var['nber_cols'] or h_var['nber_cols'] < linked_annot.nber_cols
                  h_var['nber_rows'] = linked_annot.nber_rows if !h_var['nber_rows'] or h_var['nber_rows'] < linked_annot.nber_rows
                  #  end
                end
                 logger.debug("HVAR2:" + h_var.to_json)
                ## if we consider linking datasets from other files
                #                  h_var[k].push((project_dir + dt['output_filename']) + ":" + dt['output_attr_name'])
                ## instead lets only consider the datasets from the current file and  restrict the available datasets to the file direct lineage + descendents
                dataset_field = (h_p[:h_attrs][k.to_s]['dataset_field']) ? h_p[:h_attrs][k.to_s]['dataset_field'] : "output_attr_name"
                tmp_var.push(dt[dataset_field])
                # end
                
                
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

#      puts "!H_VAR:" + h_var.to_json
#      logger.debug("!H_VAR:" + h_var.to_json)
      File.open("/data/asap2/tmp/toto.txt", "w") do |f|
        f.write(h_var.to_json + "\n")
        f.write(h_p.to_json + "\n")
      end
#       puts "Elapsed time 9d:" + (Time.now-h_p[:el_time]).to_s

      logger.debug("H_VAR: " + h_var.to_json)

      ### update parents's children
      run_parents.each do |run_parent|
        parent_run = h_parent_runs[run_parent[:run_id]]
        children_run_ids = parent_run.children_run_ids.split(",")
        children_run_ids.push(run.id)
        #        parent_run.update_attribute(:children_run_ids, children_run_ids.join(","))
        h_upd = {:children_run_ids => children_run_ids.join(",")}
        upd_run h_p[:project], parent_run, h_upd, true
      end
      
 #     puts "Elapsed time 9e:" + (Time.now-h_p[:el_time]).to_s

      ## get all runs being in the lineages ## it is already done above one by one...
      #      h_all_runs = {}
      #      Run.where(:id => all_run_ids).all.each do |run|
      #       h_all_runs[run.id]=run
      #      end
      
      ## define if predictable = there is one matrix as input                                                                                                                                      
      matrix_runs = run_parents.select{|parent| parent[:type] == 'dataset'}
      predictable = (matrix_runs.size == 1) ? true : false
      if predictable# and ! h_var['nber_cols']
        matrix_run = matrix_runs.first
        if matrix_run and matrix_run[:output_json_filename]
          h_output_json = JSON.parse(File.read(project_dir + matrix_run[:output_json_filename]))
          h_var['nber_cols'] ||= h_output_json['nber_cols'] if h_output_json['nber_cols']
          h_var['nber_rows'] ||= h_output_json['nber_rows'] if h_output_json['nber_rows']
        end
      end
      
      list_args = []
      if h_p[:h_cmd_params]['args']
          h_p[:h_cmd_params]['args'].each do |h_arg|
          logger.debug "H_ARG: " + h_arg.to_json
          std_method_attr = h_std_method_attrs[h_arg['param_key']]          
          value = (h_arg['value'] || h_var[h_arg['param_key']] || ((std_method_attr) && std_method_attr['default'])).dup
          logger.debug "VALUE: " + value.to_json + "[" + h_arg['value'].to_json + "]"
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
      logger.debug(h_env_docker_image.to_json)
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

  #    logger.debug "CMD_JSON" + h_cmd.to_json

      run_parents_to_save = []
      run_parents.each do |e|
        h_parent = {}
        [:run_id, :type, :output_attr_name, :input_attr_name].each do |k2|
          h_parent[k2] = e[k2]
        end
        run_parents_to_save.push(h_parent)
      end

      ### predict max_ram and process_duration
      h_pred_results = {}
   #   logger.debug "H_VARS: " + h_var.to_json
   #   logger.debug "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv fabdavid/asap_run:v#{h_p[:project].version_id} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{h_p[:project].version_id} #{run.std_method_id} " + "#{h_var['nber_rows']} #{h_var['nber_cols']} 2>&1'"
      if h_var['nber_rows'] and h_var['nber_cols']
        version = h_p[:project].version
        asap_docker_image = get_asap_docker(version)
        asap_docker_name = "fabdavid/asap_run:#{asap_docker_image.tag}"
#        cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv fabdavid/asap_run:v#{h_p[:project].version_id} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{h_p[:project].version_id} #{run.std_method_id} " + "#{h_var['nber_rows']} #{h_var['nber_cols']} 2>&1'"
        cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv #{asap_docker_name} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{h_p[:project].version_id} #{run.std_method_id} " + "#{h_var['nber_rows']} #{h_var['nber_cols']} 2>&1'"
            logger.debug("PRED_CMD: #{cmd}")
        pred_results_json = `#{cmd}`.split("\n").first #.gsub(/^(\{.+?\})/, "\1")                                                                                                       
        h_pred_results = Basic.safe_parse_json(pred_results_json, {})
      end
      
      h_upd = {
        :status_id => 1,
        :pred_max_ram => (h_pred_results['predicted_ram'] != 'NA') ? h_pred_results['predicted_ram'] : nil ,
        :pred_process_duration => (h_pred_results['predicted_time'] != 'NA') ?  h_pred_results['predicted_time'] : nil,
        :attrs_json => new_h_attrs.to_json,
        :command_json => h_cmd.to_json,
        :run_parents_json => run_parents_to_save.to_json,        
        :lineage_run_ids => (run_parents and run_parents.size > 0) ? (run_parents.map{|e| e[:lineage_run_ids].split(",").map{|e| e.to_i}}.flatten + run_parents.map{|e| e[:run_id]}).uniq.sort.join(",") : ""
      }

      logger.debug("H_UPD:" + h_upd.to_json)

      Basic.upd_run h_p[:project], run, h_upd, true
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
     #   puts ">#{h_cmd['container_name']}-#{h_cmd['docker_call']}"
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

    def safe_cmdline_param p
      p = p.to_s
      contains_quotes = false
      if p.match(/["']/)
        contains_quotes = true
      end
      if p.match(/['"<>\s]/) 
        p = "\"#{p}\""
        p.gsub!(/(["])/){|var| "\\#{var}"}
      end
      if p == ';'
        p = "\\;"
      end
      return p
    end

    def build_cmd h_cmd
      puts "H_CMD: " + h_cmd.to_json
      h_cmd['opts']||=[]
      h_cmd['args']||=[]
      puts "H_CMD: " + h_cmd.to_json
      
      cmd_parts = [
                   h_cmd['program'],
                   h_cmd['opts'].map{|e| "#{e['opt']} #{safe_cmdline_param(e['value'])}"}.join(" "), 
                   h_cmd['args'].map{|e| safe_cmdline_param(e['value'])}.join(" "),
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
      upd_run project, run, h_upd, true
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
      puts "run_id:#{step.id}"
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first

      h_data_types = {}
      DataType.all.map{|dt| h_data_types[dt.name] = dt}

      h_upd = {
        :status_id => 2,
        :start_time => start_time,
        :waiting_duration => start_time - run.created_at #submitted_at
      }
      upd_run project, run, h_upd, true
      project.broadcast step.id

      puts "toto!!!!"

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

      ## define abort conditions
      abort = nil
      logger.debug("Before ABORT!")
      if step.name == 'dim_reduction' and h_attrs['nber_dims'] == 3
        h_annot = {
          :run_id => h_attrs['input_matrix']['run_id'],
          :filepath =>  h_attrs['input_matrix']['output_filename'], 
          :name => h_attrs['input_matrix']['output_dataset']
        }
        if h_attrs['input_matrix']['annot_id'] 
          h_annot = {:id => h_attrs['input_matrix']['annot_id']}
        end
        annot = Annot.where(h_annot).first
        logger.debug "CHECK ABORT: " + annot.to_json
        if annot and annot.nber_cols and annot.nber_cols > 500000
          logger.debug("ABORT!")
          abort = "Too many cells (>500'000) to perfom a 3D dimension reduction"
        end
      end
      
      ## execute command                                                                                                                                                                     

      hca_output_json_file = project_dir + 'parsing' + "get_loom_from_hca.json"
      h_output_hca = Basic.safe_parse_json(File.read(hca_output_json_file), {}) if File.exist? hca_output_json_file

      all_displayed_errors = []

      if !abort and (!h_output_hca or h_output_hca['status_id'] !=4)

        h_cmd = Basic.safe_parse_json(run.command_json, {})
        puts "H_CMD: #{run.command_json} #{h_cmd.to_json}"
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
      elsif abort
        all_displayed_errors = [abort]
      elsif h_output_hca and h_output_hca['error']
        all_displayed_errors = ["Error from HCA: " + h_output_hca['error']]
      end

      output_json_filename = output_dir + 'output.json'
      h_results = {}
      if run.return_stdout == true
        h_results = Basic.safe_parse_json(res, {})
      elsif File.exist? output_json_filename
        h_results = Basic.safe_parse_json(File.read(output_json_filename), {})
      end
      
      if ! ($? and ! $?.stopped?) or h_results.is_a?(Hash) == false or h_results.keys.size == 0
        status_id = 4
        if all_displayed_errors.size > 0
          h_results['displayed_error'] = all_displayed_errors 
        else
          h_results['displayed_error'] = ['Stopped']
        end
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
      run = Run.find(run.id)
      project = run.project
      version = project.version
      asap_docker_image = get_asap_docker(version)
      step = run.step
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first
      
      ## check if the project is not archived, and if it is unarchive first                                                                
      if project.archive_status_id == 3
        #   cmd = "rails unarchive[#{project.key}]"
        #   `#{cmd}`
        Basic.unarchive(project.key)
      end
#      while project = run.project and project.archive_status_id != 1
#        sleep 1
#      end
      
      h_data_types = {}
      DataType.all.map{|dt| h_data_types[dt.name] = dt}

      h_data_classes = {}
      DataClass.all.map{|dt| h_data_classes[dt.name] = dt;  h_data_classes[dt.id] = dt}
      
      h_steps = {}
     # Step.where(:version_id => project.version_id).all.each do |s|
      Step.where(:docker_image_id => asap_docker_image.id).all.each do |s| 
        h_steps[s.id] = s
      end
      
      h_runs = {}
      project.runs.select{|r| r.status_id == 3}.each do |run|
        h_runs[run.id] = run
      end
      
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
      h_output_hca = Basic.safe_parse_json(File.read(hca_output_json_file), {}) if File.exist? hca_output_json_file
      all_displayed_errors = []
      if h_results['displayed_error'].is_a?(Array)
        all_displayed_errors = h_results['displayed_error']
      elsif h_results['displayed_error'].is_a?(String)
        all_displayed_errors.push h_results['displayed_error']
      end
      #      if !h_output_hca or h_output_hca['status_id'] !=4
      
      h_env = Basic.safe_parse_json(version.env_json, {})
puts "TEST RUN"
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
              if rendered_filename == 'output.json'
                all_displayed_errors.push("Something went wrong.") # : "#{rendered_filename} file is missing.") 
              end
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
      puts h_output_files.to_json
      ## edit type of output_files in function of properties described in output.json
      h_output_files.each_key do |k|
        h_output_files[k].each_key do |k2|           
          puts "BLA:" + k + "-->" + k2
          t = k2.split(":")
      #    puts "RELATIVE_PATH: #{t[0]}"
          relative_filepath = t[0]
        #  relative_filepath = relative_path(project, filepath)
          fo = create_upd_fo project.id, relative_filepath
      #    puts "rel_path: " + relative_filepath.to_json
      #    puts "types: " + h_output_files[k][k2]["types"].to_json
          if h_output_files[k][k2]["types"].flatten.include?("dataset")
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
              puts "DATASET name: #{dataset_name}"
              if dataset_name == '/matrix' or dataset_name.match(/^\/layers\//)
                h_output_files[k][k2]["types"].push((h_results and h_results['is_count_table'].to_i == 1) ? "int_matrix" : "num_matrix")
                h_output_files[k][k2]["nber_rows"] = h_results['nber_rows']
                h_output_files[k][k2]["nber_cols"] = h_results['nber_cols']
                h_output_files[k][k2]["dataset_size"] = (h_results['nber_rows'] and h_results['nber_cols']) ? 4 * h_results['nber_rows'] * h_results['nber_cols'] : nil
                
                h_data = {
                  'output_attr_name' => k,
                  'nber_cols' => h_results['nber_cols'],
                  'nber_rows' =>  h_results['nber_rows'],
                  'type' => 'NUMERIC',
                  'data_class_names' => h_output_files[k][k2]["types"],
                  'on' => 'EXPRESSION_MATRIX',
                  'dataset_size' => h_output_files[k][k2]["dataset_size"],                    
                  'name' => dataset_name,
                  'count' => (h_results and h_results['is_count_table'].to_i == 1) ? true : false
                }
                puts "H_DATA1: #{h_data.to_json}"
                new_annot = load_annot(run, h_data, relative_filepath, h_data_types, h_data_classes, logger)
                h_output_files[k][k2] = update_h_output_files(h_output_files[k][k2], new_annot) if new_annot
                #  puts  h_output_json.to_json
                
                if  h_metadata_by_name.keys.size > 0
                  h_metadata_by_name.each_key do |meta_name|
                    metadata = h_metadata_by_name[meta_name]                    
                     puts "H_DATA2: #{metadata.to_json}"
                    new_annot = load_annot(run, metadata, relative_filepath, h_data_types, h_data_classes, logger)
                    h_output_files[k][k2] = update_h_output_files(h_output_files[k][k2], new_annot) if new_annot
                  end
                end
              elsif h_results['metadata'] and metadata = h_metadata_by_name[dataset_name]
                # puts metadata.to_json
                h_output_files[k][k2]["nber_rows"] = metadata['nber_rows']
                h_output_files[k][k2]["nber_cols"] = metadata['nber_cols']
                h_output_files[k][k2]["dataset_size"] = metadata['dataset_size'] #() ? 4 * metadata['nber_rows'] * metadata['nber_cols']
             #   puts "load annot!"
                if metadata['type']
                  h_output_files[k][k2]["types"].push("#{metadata['type'].downcase}_mdata")
                end
                metadata['output_attr_name'] = k
                metadata['data_class_names'] = h_output_files[k][k2]["types"]
                 puts "H_DATA3: #{metadata.to_json}"
                new_annot = load_annot(run, metadata, relative_filepath, h_data_types, h_data_classes, logger)
                h_output_files[k][k2] = update_h_output_files(h_output_files[k][k2], new_annot) if new_annot
                #                if metadata['type'] == 'DISCRETE'
                #                  h_output_files[k][k2]["types"].push("categorical_annot") 
                #                elsif ['NUMERIC', 'STRING'].include? metadata['type']
                #                  h_output_files[k][k2]["types"].push("continuous_annot")
                #                end
                #  end
              end
            end
          end
          puts "K2:#{k2}"
          puts "OUTPUT_FILES:#{h_results['output_files'].to_json}"
          if h_results['output_files'] and h_results['output_files'].is_a? Hash and h_results['output_files'][k2] and h_results['output_files'][k2]["types"]
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
          if t.size == 1 ## case of docker-compose context
            t =  h_time_info['E'].split(" ")
            t.each do |part|
              if m = part.match(/([\d.]+)s/)
                part += m[1]
              elsif m = part.match(/([\d]+)m/)
                 part += m[1] * 60
              elsif m = part.match(/([\d]+)h/)
                part += m[1] * 3600
              elsif m = part.match(/([\d]+)d/)
                part += m[1] * 3600 * 24
              end
            end
          else
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
      end

      duration = (start_time) ? (Time.now - start_time) : nil 

      #  puts "OUTPUT_JSON = " +  h_output_files.to_json                                                                                                                                             
      status_id = (!h_results["original_error"] and !h_results["displayed_error"]) ? 3 : 4

      ### check if it might be a problem of memory
      #puts "BLA"
      if status_id == 4
        d = `free top`
      #  puts "FREE TOP: " + d
        free_mem = d.split(/\n/)[1].split(/\s+/)[6]
        puts "FREE MEM: " + free_mem
        if free_mem 
          diff =  free_mem.to_i - h_time_info['M'].to_i
          if diff < 10000000 #and (!h_results["displayed_error"] or h_results["displayed_error"].size == 0)
            h_results["displayed_error"].push 'Probably out of RAM. The method you are using is probably not scalable to high dimensional datasets. Please try another more scalable method (using RAM prediction tool.'
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
      
      ### compute_pred_params
      h_pred_params = set_predict_params(project, run, std_method, h_runs, h_steps)

      h_upd = {
        :output_json => h_output_files.to_json,
        :status_id => status_id,
        :duration => duration,
        :waiting_duration => (start_time) ? (start_time - run.created_at) : nil,
        :process_duration => process_duration, #h_time_info['E'].split(":"),                                      
        :process_idle_duration => h_results['time_idle'],
        :max_ram => h_time_info['M'],
        :pred_params_json => h_pred_params.to_json
      }


      #      run && run.update_attributes(h_upd)
      #      h_project_step =  Basic.get_project_step_details(project, step.id)
      #      project_step.update_attributes(h_project_step)                                                                                                              
      run && upd_run(project, run, h_upd, true)
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
        h_containers[t[0]]= {:image => t[1]}
      end
      
      return h_containers
    end

    def kill_run(run)

      if run.command_json
        h_cmd = JSON.parse(run.command_json)
        h_containers = list_containers(h_cmd['host_name'])
#        host_opt = (h_cmd['host_name'] == 'localhost') ? "localhost" : "-H #{h_cmd['host_name']}"
        ## need to create private/public key when host is not localhost
        if h_containers[h_cmd['container_name']]
          cmd = "ssh #{h_cmd['host_name']} 'docker kill #{h_cmd['container_name']}'"
          if h_cmd['host_name'] == 'localhost' and h_cmd['container_name'] and !h_cmd['container_name'].empty?
            cmd = "docker kill #{h_cmd['container_name']}"
          end
          puts cmd
          `#{cmd}`
        end
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
