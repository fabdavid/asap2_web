desc '####################### Get loom from HCA'
task :filter_de, [:annot_id] => [:environment] do  |t, args|
  
  puts 'Executing...'
  
  now = Time.now
  
  annot = Annot.find(args[:annot_id])
  project = annot.project
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
  input_file = project_dir + "de" + annot.run_id.to_s + "output.txt"					  
  @h_de_filters = JSON.parse(project.de_filter_json)	
  log_fc_threshold = Math.log(@h_de_filters['fc_cutoff'].to_f)  
  final_lists = {:down => [], :up => []}
  i = 0
  File.open(input_file, 'r') do |f|
    while (l = f.gets) do
      t = l.chomp.split("\t")
      if t[6] <= @h_de_filters['fdr_cutoff'].to_f
        if t[4] >= log_fc_threshold
          final_lists[:up].push [i, t[4], t[6]]
        elsif t[4] <= log_fc_threshold
          final_lists[:down].push [i, t[4], t[6]]
        end
      end
      i+=1
    end
  end
  
  final_lists[:up].sort!{|a, b| b[1] <=> a[1]}
  final_lists[:down].sort!{|a, b| a[1] <=> b[1]}
  
  final_lists.each_key do |k|
    filename = project_dir + 'de' + annot.run_id.to_s + "filtered.#{k}.json"
    File.open(filename, 'w') do |f|
      f.write final_lists[k].map{|e| e[0]}.to_json
    end
  end

  filename = project_dir + 'de' + 'filtered_stats.txt'
  File.open(filename, "a") do |f|
    f.write [annot.id, final_lists[:up].size, final_lists[:down].size].join("\t") + "\n"
  end		      

end
