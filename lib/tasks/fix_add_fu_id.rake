desc '####################### FIX add fu_id in projects table'
task fix_add_fu_id: :environment do
  puts 'Executing...'

  now = Time.now

  fu_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus'

  Project.all.each do |p|
    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + p.user_id.to_s + p.key
    if File.exist? project_dir    
      input_file = project_dir + ('input.' + p.extension)
      if File.exist? input_file
        link = File.readlink(input_file)
        puts "#{p.key} => #{link}"

	if link.match(/#{APP_CONFIG[:user_data_dir]}/)
          puts "USER!!!!"
	  ori_link = File.readlink(link)
          puts "New link =>" + ori_link
	  File.delete(input_file)
	  File.symlink(ori_link, input_file)          
        elsif m = link.match(/#{fu_dir}\/(\d+)/)
          puts "Found fu_id : #{m[1]}"
	  p.update_attribute(:fu_id, m[1].to_i)          
        end

      else
        puts "!!!!!!!!!!!!! INPUT file NOT found #{input_file}!!!!!!!!!!!!!" 
      end
    end
  end
  
end
