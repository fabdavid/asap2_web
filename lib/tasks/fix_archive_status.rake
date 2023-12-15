desc '####################### Fix archive status'
task fix_archive_status: :environment do
  puts 'Executing...'

  now = Time.now

  Project.where(:archive_status_id => [2,4]).all.each do |p|
    if Time.now - p.updated_at  > 120 # ensure the project is stalled at least 2 minutes
      cmd = "ps -ef | grep pigz | grep #{p.key} | wc -l" #=> should be greater than 1 if something happens       
      res = `#{cmd}`

      cmd2 = "ps -ef | grep 'unarchive[#{p.key}]' | wc -l"
      res2 = `#{cmd2}`
      
      puts res
      
      if res.to_i == 1 and res2.to_i == 1
        
        project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
        if File.exist? project_dir
          p.update_attributes(:archive_status_id => 1)
        else
          p.update_attributes(:archive_status_id => 3)
        end

      end

    end
  end		   

end
