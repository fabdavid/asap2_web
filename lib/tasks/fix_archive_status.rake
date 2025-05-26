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
          puts "set #{p.key} to unarchived"
          p.update_attributes(:archive_status_id => 1)
        else
          puts "set #{p.key} to archived"
          p.update_attributes(:archive_status_id => 3)
        end

      end

    end
  end		   


   Project.where(:archive_status_id => 1).all.each do |p|
     project_archive_path = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + (p.key + ".tgz")
     project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
     if File.exist? project_archive_path and !File.exist? project_dir
       Dir.chdir(Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s) do
         if file_size = File.size(project_archive_path) and file_size > 100
           puts "unarchiving #{project_archive_path}..."
           `tar -zxvf #{p.key + ".tgz"}`
         else
           puts "empty file => must delete and set to archived (#{project_archive_path} => #{file_size})"
            File.delete(project_archive_path)
            p.update_column(:archive_status_id => 3)
         end
       end
     end
   end
end
