desc '####################### Move fus to project'
task move_fus_to_project: :environment do
  puts 'Executing...'

  now = Time.now

  original_fus_dir = Pathname.new(APP_CONFIG[:upload_data_dir])

  #  Project.where(:key => 'ps5j41').all.each do |p|

  projects =  Project.order("id desc").all.select{|p| 
    fus = p.fus; 
    #puts fus.to_json; 
    fus.select{|fu| File.exist? original_fus_dir + fu.id.to_s}.size > 0}
  # puts projects.first.key
  #  exit
  
  projects.select{|p| !['vvv82o', 'zdfgad',  ## no fu to be added
  'gft63t', ## fu dir is absent
  'iarnd8', 'm5qx0w', 'lka4fq', '8lz511' ## archive not found
  ].include? p.key}.each do |p|
    
    puts "working on #{p.key}..."
    unarchived = false
    if p.archive_status_id == 3
      p.unarchive
      unarchived = true
    end
    #    unarchived = true
    
    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + p.user_id.to_s + p.key
    
    project_fus_dir = project_dir + 'fus'
    Dir.mkdir project_fus_dir if !File.exist? project_fus_dir
    
    input_file = Dir.entries(project_dir).select{|e| File.symlink?(project_dir + e) == true and e.match(/^input/)}.first
    if input_file
      destination_file = File.readlink(project_dir + input_file)
      
      test = false
      p.fus.sort{|a, b| b.id <=> a.id}.each do |fu|
        
        fu_dir =  Pathname.new(APP_CONFIG[:upload_data_dir]) + fu.id.to_s
        if fu_dir and File.exist? fu_dir
          
          if ! File.exist? project_fus_dir + fu.id.to_s
            
            puts "Copy #{fu_dir.to_s} -> #{project_fus_dir.to_s}..."
            FileUtils.cp_r(fu_dir, project_fus_dir) 
            ## replace symlinks
            Dir.glob(File.join(project_fus_dir + fu.id.to_s, '**', '*')).each do |entry|
              if File.symlink?(entry)
                symlink_target = File.realpath(entry)
                FileUtils.rm(entry)
                FileUtils.cp_r(symlink_target, entry)
              end
            end
          end
          if File.exist? project_fus_dir + fu.id.to_s and Dir.entries(project_fus_dir).select{|e| File.symlink?(project_fus_dir + e) == true}.size == 0
            FileUtils.rm_r fu_dir
          end
          
          test = true
          
          
        end
        
      end
      
      puts "destination_file: #{destination_file}"
      puts "input_file: #{input_file.to_s}"
      puts "move destination #{original_fus_dir.to_s} -> #{project_fus_dir.to_s}"
      # FileUtils.ln_sf(destination_file.to_s.gsub(/#{original_fus_dir.to_s}/, project_fus_dir.to_s), project_dir + input_file)
      # FileUtils.ln_sf(destination_file.to_s.gsub(/#{project_fus_dir.to_s}/, "./fus/"), project_dir + input_file)
      # FileUtils.ln_sf(destination_file.to_s.gsub(/\.\/fus\//, "./fus"), project_dir + input_file)
      FileUtils.ln_sf(destination_file.to_s.gsub(/#{original_fus_dir.to_s}/, "./fus"), project_dir + input_file)
    end


    ## rearchive if was unarchived
    if unarchived == true
      puts "Archiving..."
      logfile = "./log/fix_ge_results_archive.log"
      errfile = "./log/fix_ge_results_archive.err"
      cmd = "rails archive[#{p.key}] --trace 1> #{logfile.to_s} 2> #{errfile.to_s}"
      puts cmd
      `#{cmd}`
    end
    
#    exit
    #    exit if test == true
    
  end
  
end
