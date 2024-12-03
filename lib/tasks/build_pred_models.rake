desc '####################### Build prediction model'
task build_pred_models: :environment do
  puts 'Executing...'

  now = Time.now
  
  #  data_dir = Pathname.new(APP_CONFIG[:data_dir])
#  [5 .. 6].each do |v| # asap_docker version
  Version.all.select{|v| v.id > 4}.each do |v|

  asap_docker_image = Basic.get_asap_docker(v)
    asap_docker_version = nil
    if m = asap_docker_image.tag.match(/v(\d+)/)
      asap_docker_version = m[1]
    end
    
    puts "Version #{v.id}..."
#    cmd = "wget -qO /data/asap2/run_stats/#{v.id}.json 'https://asap.epfl.ch/versions/#{v.id}/run_stats.json'"
#    puts cmd
#    json = `#{cmd}`
    list = Basic.get_run_stats(v)  
    output_file = "/data/asap2/run_stats/#{v.id}.json"
    File.open(output_file, "w") do |f|
      f.write(list.to_json)
    end 
    `mkdir /data/asap2/pred_models/#{v.id}` if !File.exists? "/data/asap2/pred_models/#{v.id}"
    srv_volume = (v.beta == true) ? "-v /srv/asap_run/srv:/srv" : ""
    cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 #{srv_volume} fabdavid/asap_run:#{asap_docker_image.tag} -c \"Rscript prediction.tool.2.R build /data/asap2/pred_models/#{v.id} /data/asap2/run_stats/#{v.id}.json\""
    puts cmd
    `#{cmd}`
  end		   
  
end
