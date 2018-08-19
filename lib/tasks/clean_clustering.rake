desc '####################### Clean'
task clean_clustering: :environment do
  puts 'Executing...'

  now = Time.now
  
  Project.all.each do |p|
    puts "#{p.key}"
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    h_clusters = {}
    p.clusters.each do |c|
      h_clusters[c.id]=1
    end
    clustering_dir = project_dir + "clustering" 
    if File.exist? clustering_dir
      Dir.new(clustering_dir).entries.reject{|e| e.match(/^\./)}.each do |e|
        if !h_clusters[e.to_i]
          puts "   Cluster #{e} not found..."
	  FileUtils.rm_r (clustering_dir + e)
        end
      end
    end
  end
  
end
