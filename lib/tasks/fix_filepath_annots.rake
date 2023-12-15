desc '####################### Fix filepath of annots'
task fix_filepath_annots: :environment do
  puts 'Executing...'

  now = Time.now
  
  Project.all.each do |p|
    
    p.annots.each do |a|
   
      if !a.filepath.match(/#{a.store_run_id}/) and !a.filepath.match(/parsing/)
        puts "Problem: #{a.store_run_id} <=> #{a.filepath}"
	puts "Corrected: " + a.filepath.gsub(/(\d+)/, a.store_run_id.to_s)
	a.update_attribute(:filepath, a.filepath.gsub(/(\d+)/, a.store_run_id.to_s))	
      end

    end

  end
  
end
