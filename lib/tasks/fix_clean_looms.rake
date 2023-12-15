desc '####################### Clean looms'
task fix_clean_looms: :environment do
  puts 'Executing...'
  
  now = Time.now
  
  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  
  projects = Project.where(:key => 'kvvxcr').all
  projects.each do |p|
    
    project_dir = data_dir + 'users' + p.user_id.to_s + p.key    

    h_annots = {}    
    p.annots.each do |a|
    h_annots[a.filepath]||={}
      h_annots[a.filepath][a.name] = 1
    end	  
    
    p.fos.select{|fo| fo.ext == 'loom'}.each do |fo|
      cmd = "java -jar lib/ASAP.jar -T ListMetadata -f #{project_dir + fo.filepath}"
      puts cmd
     res = `#{cmd}`
#     puts res
      h_res = Basic.safe_parse_json("{" + res + "}", {})
      if h_res['metadata']
        h_res['metadata'].each do |meta|
#	puts "#{meta.to_json}..."
          if !h_annots[fo.filepath][meta['name']]
            puts "Metadata TO DELETE: #{meta.to_json}"
            cmd = "java -jar lib/ASAP.jar -T RemoveMetaData -o tmp/ -loom #{project_dir + fo.filepath} -meta #{meta['name']} 2>&1 > tmp/bla.txt"
            puts cmd
            `#{cmd}`

          end
        end
      end	
    end
    
  end		

end
