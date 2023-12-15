desc '####################### Run marker genes'
task run_marker_genes: :environment do
  puts 'Executing...'

  now = Time.now
  logger = Logger.new("log/run_marker_genes.log")
  Project.where(:key => ['p87vw4', '8vcl1w']).all.each do |p|
    version = p.version
    asap_docker_image = Basic.get_asap_docker(version)

    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    h_env = JSON.parse(p.version.env_json)
    #    find_marker_step = Step.where(:version_id => p.version_id, :name => 'markers').first
    find_marker_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'markers').first
    
    #    find_marker_enrichment_step = Step.where(:version_id => p.version_id, :name => 'marker_enrich').first
    find_marker_enrichment_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'marker_enrich').first
    
    if find_marker_step and find_marker_enrichment_step
      
      annots = Annot.where(:project_id => p.id, :dim => 1, :data_type_id => 3).all
      
      if p.archive_status_id != 1
        cmd = "rails unarchive[#{p.key}]"
        puts cmd
        `#{cmd}`
      end
      
      annots.each do |annot|
      
        h_markers = Basic.find_markers(logger, p, annot, annot.user_id)
        h_marker_enrichment = Basic.find_marker_enrichment(logger, p, annot, h_markers[:run], annot.user_id)
    
      end
    end
  end

end
