desc '####################### Change project key'
task :change_project_key, [:project_key, :new_project_key, :dry_run] => [:environment] do |t, args|
  puts 'Executing...'
  
  new_project_key = args[:new_project_key]

  now = Time.now

  ## first check new project_key doesn't exist
  if Project.where(:key => new_project_key).first
    puts "Project #{new_project_key} already exist!"
    exit
  end

  dry_run = args[:dry_run]

  project_key = args[:project_key]  
  project = Project.where(:key => project_key).first
  version = project.version
  h_env = JSON.parse(version.env_json)

  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key	
  new_project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + new_project_key

  def replace e, h, project_key, new_project_key, dry_run
    h.each_key do |k|
      if h[k].is_a? String
        puts "KEY #{k}"
        if h[k] == project_key
          h[k] = new_project_key
        end
        h[k].to_s.gsub!(/\/#{project_key}\//, "/#{new_project_key}/")
        h[k].to_s.gsub!(/\[#{project_key}\]/, "[#{new_project_key}]")
        puts "--->mod!!\n"
        puts h[k]
        if h[k].match(/#{project_key}/)
          puts "--->REMAINS!!!!!!!!!!"
        end
        if dry_run == '0'
          e.update_attributes(h)
        end
      end
    end
  end
  
  project.runs.each do |run|
    h_run = run.attributes
    replace(run, h_run, project_key, new_project_key, dry_run)
  end

  project.active_runs.each do |active_run|
    h_active_run = active_run.attributes
    replace(active_run, h_active_run, project_key, new_project_key, dry_run)
  end	

  project.del_runs.each do |del_run|
    h_del_run = del_run.attributes
    replace(del_run, h_del_run,  project_key, new_project_key, dry_run)
  end
  
  project.reqs.each do |req|
    h_req = req.attributes
    replace(req, h_req, project_key, new_project_key, dry_run)
  end
  
  project.annots.each do |annot|
    h_annot = annot.attributes
    replace(annot, h_annot, project_key, new_project_key, dry_run)
  end

  project.fus.each do |fu|
    h_fu = fu.attributes
    replace(fu, h_fu, project_key, new_project_key, dry_run)
  end
  
  project.fos.each do |fo|
    h_fo = fo.attributes
    replace(fo, h_fo, project_key, new_project_key, dry_run)
  end


  ### replace recursively project_key in files

  Dir.chdir(project_dir) do 	      
    Dir.glob("**/*") do |filename|
      puts "replace text in file #{filename}"
      if m = filename.match(/\.(log|out|err|json)$/)
        puts m[1]
        text = File.read(filename)
        text.gsub!(/\/#{project_key}\//, "/#{new_project_key}/")
        text.gsub!(/\[#{project_key}\]/, "[#{new_project_key}]")
        text.gsub!(/\"#{project_key}\"/, "\"#{new_project_key}\"")
        text.gsub!(/\n#{project_key}\n/, "\n#{new_project_key}\n")
        if text.match(/#{project_key}/)
          puts "====>REMAINS!!!"
        end
        if dry_run == '0'
          File.open(filename, "w") { |file| file.puts text }
        end
      end
    end
  end

  
  ### change project dir name
  FileUtils.mv project_dir, new_project_dir if dry_run == '0'

  project.update_attribute(:key, new_project_key) if dry_run == '0'

  
end
