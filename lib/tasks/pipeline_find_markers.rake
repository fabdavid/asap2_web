desc '####################### Pipeline Find Markers'
task :pipeline_find_markers, [:project_key, :meta_id, :user_id] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now

   logger = Logger.new("log/pipeline_find_markers.log")  

   project = Project.where(:key => args[:project_key]).first
   meta = Annot.where(:id => args[:meta_id]).first
   user = User.where(:id => args[:user_id]).first

  Basic.find_markers logger, project, meta, user.id

  Basic.find_markers_enrichment logger, project, meta, user.id


end
