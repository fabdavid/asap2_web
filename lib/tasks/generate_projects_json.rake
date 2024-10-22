desc '####################### Generate projects.json'
task generate_projects_json: :environment do
  puts 'Executing...'

  now = Time.now

  @public_projects = Project.where(:public => true).all

  
  # Set the ActiveRecord logger level to a higher level to suppress SQL logs
  old_logger_level = ActiveRecord::Base.logger.level
  ActiveRecord::Base.logger.level = 1  # 1 corresponds to :info level
  
  begin			    
    
    h_references = {}
  Article.all.map{|a| h_references[a.doi] = a}
  h_organisms = {}
  Organism.all.map{|e| h_organisms[e.id] = e}
  h_identifier_types = {}
  IdentifierType.all.map{|it| h_identifier_types[it.id] = it}
  h_cla_sources = {}
  ClaSource.all.map{|cla_source| h_cla_sources[cla_source.id] = cla_source}
  h_cell_ontologies = {}
  CellOntology.all.map{|co| h_cell_ontologies[co.id] = co}
  h_envs = {}
  Version.all.map{|v| h_envs[v.id] = Basic.safe_parse_json(v.env_json, {})}
  h_steps = {}
  Step.all.map{|s| h_steps[s.id] =s}
  h_std_methods = {}
  StdMethod.all.map{|s| h_std_methods[s.id] = s}
  h_project_types = {}
  ProjectType.all.map{|e| h_project_types[e.id] = e}
  
  l =
    @public_projects.map{|p|
      Basic.generate_project_json(p)	
    }
      
    # puts l.to_json
    
    File.open(Pathname.new(APP_CONFIG[:data_dir]) + "projects.json", 'w') do |f|
      f.write(l.to_json)
    end				 
      
    ensure
      # Reset the logger level back to the original level after the task is done
      ActiveRecord::Base.logger.level = old_logger_level
    end
  
end
