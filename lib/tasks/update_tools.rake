desc '####################### Update tools'
task update_tools: :environment do
  puts 'Executing...'

  now = Time.now

  version_id = 7

  version = Version.find(version_id) #where(:version_id => version_id).first
  
  h_env = Basic.safe_parse_json(version.env_json, {})

  tool_types = ToolType.all
  h_tool_types={}
  h_tools = {}
  #puts tool_types.to_json
  #xexit
  tool_types.map{|tt| h_tools[tt.name] = {}; h_tool_types[tt.id] = tt}
  
  tools = Tool.all
  tools.select{|t| h_tools[h_tool_types[t.tool_type_id].name]}.map{|t| h_tools[h_tool_types[t.tool_type_id].name][t.package] = t}

  h_dockers = {}
  h_env['docker_images'].each_key do |k|  
    h_dockers[k] = {:name => h_env['docker_images'][k]['name'], :ref => "#{h_env['docker_images'][k]['name']}:#{h_env['docker_images'][k]['tag']}", :tag => h_env['docker_images'][k]['tag']}
  end				  
  #docker_name = "#{h_env['docker_images']['asap_run']['name']}:#{h_env['docker_images']['asap_run']['tag']}"

  
  res =  Basic.sql_query2(:asap_data, h_env['asap_data_db_version'], 'genes', "join organisms on (organism_id = organisms.id) join ensembl_subdomains on (ensembl_subdomain_id = ensembl_subdomains.id)", 'max(genes.latest_ensembl_release) as m', "ensembl_subdomains.name = 'vertebrates'")
  ensembl_vertebrate_version =  res[0]['m']
  puts ensembl_vertebrate_version
  h_env['tool_versions']['ensembl_vertebrate'] = ensembl_vertebrate_version
  
   res =  Basic.sql_query2(:asap_data, h_env['asap_data_db_version'], 'genes', "join organisms on (organism_id = organisms.id) join ensembl_subdomains on (ensembl_subdomain_id = ensembl_subdomains.id)", 'max(genes.latest_ensembl_release) as m', "ensembl_subdomains.name = 'fungi'")
   ensembl_genomes_version =  res[0]['m']
  puts ensembl_genomes_version
  h_env['tool_versions']['ensembl_genomes'] = ensembl_genomes_version

  list_r_packages = {"fabdavid/asap_run" => ["Matrix", "reticulate", "KernSmooth", "nlme", "MASS", "sanon", 'R6', 'bit64', 'Rtsne', 'jsonlite', 'data.table', 'devtools', 'flexmix', 'rPython', 'statmod', 'plotly', 'future.apply', 'Seurat', 'MAST', 'rhdf5', 'M3Drop', 'sva', 'DESeq2', 'limma', 'cluster', 'Cairo', 'scater', 'SC3', 'XVector', 'scran', 'hdf5r']}

  h_dockers.each_key do |k|
    puts h_dockers[k][:name]
    puts list_r_packages[h_dockers[k][:name]]

    ## get or create docker_image
    docker_image = DockerImage.where(:name => h_dockers[k][:name], :tag => h_dockers[k][:tag]).first
    if !docker_image
      h_docker_image = {
        :name => h_dockers[k][:name], :tag => h_dockers[k][:tag]
      }
      docker_image = DockerImage.new(h_docker_image)
      docker_image.save
    end
   
    h_docker_tools = Basic.safe_parse_json(docker_image.tools_json, {})
    
    cmd = "docker run --entrypoint '/bin/sh' --rm #{h_dockers[k][:ref]} -c \"Rscript -e 'x<-c(" + list_r_packages[h_dockers[k][:name]].map{|e| "\\\"#{e}\\\""}.join(", ") + "); lapply(x, require, character.only = TRUE); sessionInfo()'\""
    res = `#{cmd}`
    puts cmd
    puts res
   
    res.split(/\n/).each do |l|
      puts l
      if m = l.match(/R version ([\d\.]+)/)
        h_docker_tools["r"] = m[1]
      elsif m = l.match(/^\s*\[\d+\](.+?)$/)
        t = m[1].strip.split(/\s+/)
        t.each do |e|
          puts "e:" +  e
          if m2 = e.match(/^(.+?)_([\d\.]+)$/)
            if m2[1] and h_tools["R"][m2[1]]
              
              h_docker_tools[h_tools["R"][m2[1]].name] = m2[2]
            end
          end
        end
      end
    end			

    cmd = "docker run --entrypoint '/bin/sh' --rm #{h_dockers[k][:ref]} -c \"python#{(version_id > 4) ? '3' : ''} --version 2>&1 \""
    res = `#{cmd}`
    puts cmd
    puts "-#{res}-"
    if m = res.match(/Python ([\d\.]+)/)
      h_docker_tools["python#{(version_id > 4) ? '3' : ''}"] = m[1]
      puts m[1]
    end

    cmd = "docker run --entrypoint '/bin/sh' --rm #{h_dockers[k][:ref]} -c \"pip list\""
    res = `#{cmd}`
    puts cmd
    puts "-#{res}-"

    res.split(/\n/).each do |l|
      puts l
      t = l.strip.split(/\s+/)
      if h_tools["Python"][t[0]]
        h_docker_tools[h_tools["Python"][t[0]].name] = t[1]
      end
    end

    cmd = "docker run --entrypoint '/bin/sh' --rm #{h_dockers[k][:ref]} -c \"java -version 2>&1\""
    res = `#{cmd}`
    puts cmd
    puts "-#{res}-"
    res.split(/\n/).each do |l|
      puts l
      if m = l.match(/openjdk version \"([\d\.]+)/)
        h_docker_tools["java"] = m[1]
      end
    end
    
    docker_image.update_attributes({:full_name => docker_image.name + ":" + docker_image.tag, :tools_json => h_docker_tools.to_json})
    
  end

  ## get ontologies versions (for ontologies that are used to create gene sets) if last version (this file contains the last ASAP version's tool versions)
  if Version.last.id == version_id
    tools_versions_file = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + "tool_versions.json"
    h_tools_versions = Basic.safe_parse_json(File.read(tools_versions_file), {})        
    tmp_k = h_tools_versions.keys
    tmp_k.each do |k|
      h_tools_versions[k.downcase] = h_tools_versions[k]
      h_tools_versions.delete(k)
    end
    ['hcao', 'fbbt'].each do |k|
      h_env['tool_versions'][k] = h_tools_versions[k]
    end
  end

  version.update_attributes({:env_json => h_env.to_json})

end
