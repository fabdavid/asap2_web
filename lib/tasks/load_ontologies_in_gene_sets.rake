desc '####################### Load ontologies in gene sets'
task load_ontologies_in_gene_sets: :environment do
  puts 'Executing...'

  now = Time.now
puts ENV.to_json

#  flybase_ontology = CellOntology.where(:name => 'Flybase Anatomy Ontology').first

#  version_id = ENV['RAILS_ENV'].gsub(/(^.*_v)/, '')
  
#  puts version_id 
#  version_id = Version.last.id

  h_organisms = {}
  
  organisms = Organism.all
  organisms.map{|o| h_organisms[o.id] = o}

  version_id = ''
  puts organisms.size
  
  ConnectionSwitch.with_db(:website_with_version, nil) do 
    
    version_id = Version.last.id
    
    #    tool = Tool.where(:label => 'Flybase Anatomy Ontology').first
    #    if !tool
    #      h_tool = {
    #        :name => 'fbbt',
    #        :label => 'Flybase Anatomy Ontology',
    #        :tool_type_id => 1,
    #        :step_ids => "",
    #        :description => "Flybase Anatomy Ontology"
    #      }
    #      tool = Tool.new(h_tool)
    #      tool.save
    #    end
    #    
    #    tool = Tool.where(:label => 'Human Cell Atlas Ontology').first
    #    if !tool
    #      h_tool = {
    #        :name => 'hcao',
    #        :label => 'Human Cell Atlas Ontology',
    #        :tool_type_id => 1,
    #        :step_ids => "",
    #        :description => "Human Cell Atlas Ontology"
    #      }
    #      tool = Tool.new(h_tool)
    #      tool.save
    #    end
    #  end
    #
  end
  puts organisms.size
  
  ontologies = [
                {:organism_id => 35, :cell_ontology_id => 2, :label => 'Flybase Anatomy Ontology', :name => 'fbbt', :tag => 'FBbt'},
                {:organism_id => 1, :cell_ontology_id => 1, :label => 'Human Cell Atlas Ontology', :name => 'hcao', :tag => 'HCAO'}
               ]
  
  #  organism_id = 35
  
  ontologies.each do |ontology|
    
    h_gene_sets = {}

    tool = nil

    ConnectionSwitch.with_db(:website_with_version, nil) do
      
      tool = Tool.where(:name => ontology[:name]).first
      if !tool
        h_tool = {
          :name => ontology[:name],
          :label => ontology[:label],
          :tool_type_id => 1,
          :step_ids => "",
          :description => ontology[:label]
        }
        tool = Tool.new(h_tool)
        tool.save
      end
    end
    
    #    tool = Tool.find_by_label(ontology[:label])
    
    res = Basic.sql_query2(:asap_development, nil, 'cell_ontology_terms', '', 'identifier, name, related_gene_ids', "cell_ontology_id = #{ontology[:cell_ontology_id]} and related_gene_ids != ''")
    res.each do |gs|
      h_gene_sets[gs.identifier] = {:name => gs.name, :gene_ids => gs.related_gene_ids.split(",")}
    end
    
    if h_gene_sets.keys.size > 0
      
      #create table tools(
      #id serial,
      #name text,
      #label text,
      #tool_type_id int references tool_types,
      #step_ids text,
      #description text,
      #created_at timestamp,
      #updated_at timestamp,
      #primary key (id)
      #);
    
      #create table db_sets(
      #id serial,
      #tool_id int references tools,
      #label text,
      #tag text, -- used for filename (databases)
      #primary key (id)
      #);
      
    db_set = DbSet.where(:tool_id => tool.id).first
      if !db_set
      h_db_set = {
          :tool_id => tool.id,
          :label => tool.label,
          :tag => ontology[:tag]
        }
        db_set = DbSet.new(h_db_set)
        db_set.save
      end
      
      #        Column       |            Type             |                       Modifiers                        
      #-------------------+-----------------------------+--------------------------------------------------------
      # id                | integer                     | not null default nextval('gene_sets_id_seq'::regclass)
      # user_id           | integer                     | 
      # project_id        | integer                     | 
      # organism_id       | integer                     | 
      # label             | text                        | 
      # original_filename | text                        | 
      # created_at        | timestamp without time zone | 
      # updated_at        | timestamp without time zone | 
      # nb_items          | integer                     | default 3
      # tool_id           | integer                     | 
      # ref_id            | integer                     | 
      # asap_data_id      | integer                     | 
      # obsolete          | boolean                     | default false
      
      gene_set = GeneSet.where(:organism_id => ontology[:organism_id], :tool_id => tool.id, :ref_id => db_set.id).first
      #  puts gene_set.to_json
    if !gene_set 
      h_gene_set = {
        :user_id => 1,
          :organism_id => ontology[:organism_id],
          :label => tool.label,
          :nb_items => h_gene_sets.keys.size,
          :tool_id => tool.id,
          :ref_id => db_set.id,
          :asap_data_id => version_id,
          :latest_ensembl_release => h_organisms[ontology[:organism_id]].latest_ensembl_release
        }
      
      gene_set = GeneSet.new(h_gene_set)
      gene_set.save
    end
      #    id   | gene_set_id | identifier |   name   | 
      
      
      h_gene_sets.each_key do |k|
        gene_set_item = GeneSetItem.where(:gene_set_id => gene_set.id, :identifier => k).first
        h_gene_set_item = {
        :identifier => k,
          :gene_set_id => gene_set.id,
          :name => h_gene_sets[k][:name],
          :content => h_gene_sets[k][:gene_ids].join(","),
          :asap_data_id => version_id
        }
        if !gene_set_item
          gene_set_item = GeneSetItem.new(h_gene_set_item)
          gene_set_item.save
        else
          gene_set_item.update_attributes(h_gene_set_item)
        end
    end
      
      puts h_gene_sets
      
      #  flybase_ontology.cell_ontology_terms.select{|e| e.related_gene_ids != ''}.each do |term|
      #if term.content_json.match(/expresses/)
      #  h_content = Basic.safe_parse_json(term.content_json, {})
      #  puts h_content.to_json
      #      h_gene_sets[term.name] = term.related_gene_ids.split(",")
      #end
      #  end
      
    end
  end
end
