desc '####################### Fix fos 3 => remove duplicated filepaths'
task fix_fos3: :environment do
  puts 'Executing...'

  now = Time.now

  warnings = []

  Project.order("id").all.each do |p|
    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + "users" + p.user_id.to_s + p.key
    
    if File.exist? project_dir
      
#      p.fos.each do |fo|
#        if Fo.where(:filepath => fo.filepath, :project_id => fo.project_id).count > 1
#          warnings.push "Delete fo " + p.id.to_s + " => " + fo.id.to_s + " [#{project_dir + fo.filepath}]"
#	  fo.destroy
#          
#        elsif !File.exist?(project_dir + fo.filepath)
#          warnings.push "File absent! Delete fo " + p.id.to_s + " => " + fo.id.to_s + " [#{project_dir + fo.filepath}]"
#	  fo.destroy
#        end
#      end
      
      h_filepaths = {}
      p.annots.each do |a|
        if File.exist? project_dir + a.filepath
          h_filepaths[a.filepath] = a          
        end
      end

      h_filepaths.each_key do |filepath|
        if !Fo.where(:project_id => p.id, :filepath => filepath).first
         puts "Create new Fo"
          annot = h_filepaths[filepath]
          h_fo = {
            :project_id => p.id,
            :user_id => annot.user_id,
            :run_id => annot.store_run_id,
            :filepath => filepath,
	    :filesize => File.size(project_dir + filepath),
            :ext => 'loom'
          }
          fo = Fo.new(h_fo)
          fo.save
          puts "create fo" + fo.to_json
        end
      end
      
    end
  end
  puts  warnings.join("\n")
  
end
