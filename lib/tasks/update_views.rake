desc '####################### Update views'
task update_views: :environment do
  puts 'Executing...'

  now = Time.now
  now_year = now.year.to_s
  
  Project.where("last_day_session_ids != ''").all.each do |p|
    
    puts "Project #{p.key}..."
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key

    if File.exist?(project_dir)
    
      nber_new_views = p.last_day_session_ids.split(",").size
      
      nber_views_by_day_file = project_dir + '.stats_by_day'
      
      h_nber_views_by_day = {}
      
      if File.exist?(nber_views_by_day_file)
        h_nber_views_by_day = Basic.safe_parse_json(File.read(nber_views_by_day_file), {})
      end    
      
      d = now-1.day
      chunk_i = nil
      if !h_nber_views_by_day[now_year]
        puts "Year doesn't exist yet!"
        h_nber_views_by_day[now_year] ||= [{"start" => "#{d.year}-#{d.month}-#{d.day}", "views" => []}]
        chunk_i = 0
      else
        puts "Year exists"
        last_chunk = h_nber_views_by_day[now_year].last
        
        tmp_d = last_chunk["start"].split("-")
        puts (Time.new(tmp_d[0], tmp_d[1], tmp_d[2]) + (last_chunk["views"].size - 1).day).to_s + "<=>" +  Time.new(d.year, d.month, d.day).to_s
        
        if Time.new(tmp_d[0], tmp_d[1], tmp_d[2]) + (last_chunk["views"].size - 1).day  != Time.new(d.year, d.month, d.day)
          puts "New chunk" 
          h_nber_views_by_day[now_year].push({"start" => "#{d.year}-#{d.month}-#{d.day}", "views" => []})
        else
          puts "Add to existing chunk"
        end
        chunk_i =  h_nber_views_by_day[now_year].size-1
      end
      
      h_nber_views_by_day[now_year][chunk_i]["views"].push nber_new_views
      
      File.open(nber_views_by_day_file, 'w') do |f|
        f.write h_nber_views_by_day.to_json
        puts h_nber_views_by_day.to_json
      end
      
      p.update_attributes({:nber_views => p.nber_views + nber_new_views, :last_day_session_ids => ''})   
      Basic.upd_project_size p

    end
  end
  
end
