desc '####################### Fix docker tag'
task fix_docker_tag: :environment do
  puts 'Executing...'

  now = Time.now
  
  Project.all.each do |p|
 
    p.runs.select{|r| r.step_id !=1}.each do |r|
   
      puts r.to_json
      
      r.update_attribute(:command_json, r.command_json.gsub(/fabdavid\/asap_run\:v2/, "fabdavid/asap_run:v4"))
      
     # exit
    end

  end
  
end
