desc '####################### Integrate'
task :integrate, [:project_key] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now
  logger = Logger.new("log/exec_run.log")
  puts args[:project_key]

  project_key = args[:project_key]
  project = Project.where(:key => project_key).first
  version = project.version
  h_env = JSON.parse(version.env_json)

  h_env_docker_image = h_env['docker_images']['asap_run']
  image_name = h_env_docker_image['name'] + ":" + h_env_docker_image['tag']

  asap_docker_image = Basic.get_asap_docker(version)

  db_conn = "postgres:5434/asap2_data_v" + h_env['asap_data_db_version'].to_s #project.version_id.to_s
  
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
  tmp_dir = project_dir + 'parsing'
  Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

  puts "ASAP_DOCKER_IMAGE_ID:" + asap_docker_image.id.to_s
  parsing_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'parsing').first
  run = Run.where(:project_id => project.id, :step_id => parsing_step.id).first

  h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.name] = dt}

  h_data_classes = {}
  DataClass.all.map{|dt| h_data_classes[dt.name] = dt; h_data_classes[dt.id] = dt}

  if project
    puts "integrate"

    p = JSON.parse(project.parsing_attrs_json) if project.parsing_attrs_json

    output_json_file = project_dir + 'parsing' + "output.json"

    h_attrs = JSON.parse run.attrs_json
    puts h_attrs.to_json
    
    project_keys = h_attrs['integrate_batch_paths'].keys

    projects = Project.where(:key => project_keys).all

    file_paths = projects.map{|p|
      p_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
      p_dir + 'parsing' + 'output.loom'
    }.join(",")
    batch_paths = projects.map{|p|
      h_attrs['integrate_batch_paths'][p.key]
    }.join(",")

    rds_file = project_dir + 'parsing' + "output.rds"
    
    h_cmd = {
      'host_name' => "localhost",
      'time_call' => h_env["time_call"].gsub(/\#output_dir/, tmp_dir.to_s),
      'container_name' => APP_CONFIG[:asap_instance_name] + "_" + run.id.to_s,
      'docker_call' => h_env_docker_image['call'].gsub(/\#image_name/, image_name),
      'program' => "Rscript integration.R",  #(mem > 10) ? "java -Xms#{mem}g -Xmx#{mem}g -jar /srv/ASAP.jar" : 'java -jar /srv/ASAP.jar',                                                       
        'opts' => {},
        'args' => [
          {"param_key" => 'input_loom_path_list', "value" => file_paths},
          {"param_key" => 'nput_batch_path_list', "value" => batch_paths},
          {"param_key" => 'input_n_pcs', "value" => h_attrs['integrate_n_pcs']},
          {"param_key" => 'output_rds_path', "value" => rds_file},
          {"param_key" => 'output_convergence_plot', "value" => project_dir + 'parsing' + "convergence_plot.png"}
        ]
      }

      output_file = tmp_dir + "output.loom"
      output_json = tmp_dir + "output.json"

      puts h_cmd
      cmd = Basic.build_cmd(h_cmd)
      puts "CMD_R:" + cmd
      `#{cmd}`
      
      docker_call_v7 = "docker run --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v7 -c"
#      loom_file = project_dir + 'parsing' + "output.loom"
      input_loom_file = project_dir + 'input.loom'
      cmd = "#{docker_call_v7} 'Rscript --vanilla /srv/convert_seurat.R #{rds_file.to_s} #{input_loom_file.to_s}'"
      puts cmd
      `#{cmd}`

      ## preparse
      options = []
      output_dir = project_dir + 'parsing'
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T Preparsing #{options.join(" ")} -organism #{project.organism_id} -f \"#{input_loom_file}\" -o #{output_dir} -h localhost:5434/asap2_development 2> #{output_dir + 'preparsing_output.err'}"
      puts cmd
      `#{cmd}`
      h_preparsing = JSON.parse(File.read(output_dir + 'output.json'))
      puts "h_preparsing: #{h_preparsing.to_json}"
      
      parsing_attrs = JSON.parse(project.parsing_attrs_json)
      ['nber_cols', 'nber_rows', 'file_type'].each do |e|
        parsing_attrs[e] = h_preparsing['list_groups'][0][e]
      end
      puts parsing_attrs.to_json
      project.update_column(:parsing_attrs_json, parsing_attrs.to_json)
      puts project.parsing_attrs_json
      ## parse

#      cmd = "rails parse[#{project.key}]"
#      puts cmd
#      `#{cmd}`
      
      mem = parsing_attrs["nber_cols"].to_i * parsing_attrs["nber_rows"].to_i * 128 / (31053 * 1474560) # project sample = gi6qfz     
      h_env_docker_image = h_env['docker_images']['asap_run']
      image_name = h_env_docker_image['name'] + ":" + h_env_docker_image['tag']

      opts = [
               {'opt' => "-ncells", 'value' => parsing_attrs["nber_cols"]},
               {'opt' => "-ngenes", 'value' => parsing_attrs["nber_rows"]},
               {'opt' => "-type", 'value' => 'LOOM'},
               {'opt' => '-T', 'value' => "Parsing"},
               {'opt' => "-organism", 'value' => project.organism_id},
               {'opt' => "-o", 'value' => tmp_dir},
               {'opt' => "-f", 'value' => input_loom_file},
               {'opt' => '-h', 'value' => db_conn}
      ]
            
      h_cmd_parse = {
        'host_name' => "localhost",
        'time_call' => h_env["time_call"].gsub(/\#output_dir/, tmp_dir.to_s),
        'container_name' => APP_CONFIG[:asap_instance_name] + "_" + run.id.to_s,
        'docker_call' => h_env_docker_image['call'].gsub(/\#image_name/, image_name),
        'program' => "java -jar ASAP.jar",  #(mem > 10) ? "java -Xms#{mem}g -Xmx#{mem}g -jar /srv/ASAP.jar" : 'java -jar /srv/ASAP.jar',   
        'opts' => opts,
        'args' => []
      }
      
      output_file = tmp_dir + "output.loom"
      output_json = tmp_dir + "output.json"
      
      puts h_cmd_parse
      cmd_parse = Basic.build_cmd(h_cmd_parse)
      puts "CMD_JAVA:" + cmd_parse
      `#{cmd_parse}`
      h_parsing = Basic.safe_parse_json(File.read(output_json), {})
#      puts h_parsing.to_json
#      puts project.to_json
      project.update_columns({:nber_cols => h_parsing["nber_cols"], :nber_rows => h_parsing["nber_rows"], :extension => 'loom'})
#      puts project.to_json
  end

end
