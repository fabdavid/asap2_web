desc '####################### Load FCA annotations'
task load_fca_annotations: :environment do
  puts 'Executing...'

  now = Time.now

  #get fly genes

  genes = Basic.sql_query2(:asap_data, 6, 'genes', '', 'id, ensembl_id, name, alt_names, description', "organism_id = 35")
  h_genes = {}
  genes.map{|g| g['obsolete_alt_names'].split(",").map{|a| h_genes[a]=g} if g['obsolete_alt_names'] }
  genes.map{|g| g['alt_names'].split(",").map{|a| h_genes[a]=g} if g['alt_names'] }
  genes.map{|g| h_genes[g['name']] = g; h_genes[g['ensembl_id']] = g;}

  
  #get ontologies  
  cots = CellOntologyTerm.all
  h_cots = {}
  cots.map{|e| h_cots[e.identifier] = e.id}

  fca_provider = Provider.find_by_tag('FCA')
  
  fca_projects = fca_provider.provider_projects

  public_ids = fca_projects.map{|e| e.projects}.flatten.uniq.map{|p| p.public_id}.compact.sort

#exit   

  projects = Project.where(:public_id => public_ids).all
#projects = Project.where(:key => '0t47gk').all
  projects.each do |project|

    ## get cell_sets                                                                                                                                                                                                                
    h_cell_sets = {}
    annot_cell_sets = project.annot_cell_sets
    annot_cell_sets.each do |annot_cell_set|
      h_cell_sets[[annot_cell_set.annot_id, annot_cell_set.cat_idx]] = annot_cell_set.cell_set_id
    end

    version = project.version
    #  h_env = Basic.safe_parse_json(version.env_json, {})
    asap_docker_image = Basic.get_asap_docker(version)
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    
    loom_file = project_dir + 'parsing' + 'output.loom'
    
    h_steps = {}
    Step.where(:docker_image_id => asap_docker_image.id).all.each do |s|
      h_steps[s.id] = s
    end
    
    parsing_run = project.runs.select{|r| h_steps[r.step_id].name == 'parsing'}.first
    next if !parsing_run
    global_metadata = Annot.where(:project_id => project.id, :run_id => parsing_run.id, :name => '/attrs/MetaData').first
    
    #  puts global_metadata.to_json
    
    cmd = "java -jar /srv/asap_run/srv/ASAP.jar -T ExtractMetadata -type STRING -names -loom #{project_dir}/parsing/output.loom -meta \"/attrs/MetaData\""
    h_metadata = Basic.safe_parse_json(`#{cmd}`, {})
    
    #  puts h_metadata['values'][0]
    h_metadata_content = Basic.safe_parse_json(h_metadata['values'][0], {})
    
    h_nber_items = {}
    
    #  puts h_metadata_content['clusterings'].to_json
    
    #{"id":241,"description":"stretch follicle cell","cell_type_annotation":[{"data":{"curator_name":"FCA BioHub Community","curator_id":"","timestamp":-1,"obo_id":"FBbt:00004908","ols_iri":"http://purl.obolibrary.org/obo/FBbt_00004908","annotation_label":"stretch follicle cell","markers":["cv-2","dpp"],"publication":"","comment":"Tissues: ovary. This annotation was curated from the following raw annotations: stretch follicle cell (FBbt:00004908, http://purl.obolibrary.org/obo/FBbt_00004908; Annotation from R version: clustering Leiden resolution 0.8, cluster 15.0 (ovary))."},"validate_hash":"N.A.","votes":{"votes_for":{"total":1,"voters":[{"voter_name":"Katja Rust","voter_id":"0000-0001-6367-5994","voter_hash":"a11e358a059628abc23ee4313441a4f8528abc87ed8845a4c4bdd9aae2254468"}]},"votes_against":{"total":0,"voters":[]}}}]}
    
    h_metadata_content['clusterings'].each do |clustering|
      
      puts "ID: " + clustering['id'].to_s
      puts "Name: " + clustering['name']
      puts "Group: " + clustering['group']
      
      ## matching annot
      puts Annot.where(:project_id => project.id, :run_id => parsing_run.id, :dim => 1).all.map{|e| e.name}.join(", ")
     
      annot = Annot.where(:project_id => project.id, :run_id => parsing_run.id, :name => "/col_attrs/Clustering_" + clustering['name'].gsub(/[ ()\,]/, "_")).first
      if annot
        puts "ANNOT: " + annot.id.to_s
        list_cats = Basic.safe_parse_json(annot.list_cat_json, [])
        puts "List_cats:" + list_cats.to_json
        puts "Clusters: " + clustering['clusters'].size.to_s
        
        clustering['clusters'].select{|c| c['cell_type_annotation'] and c['cell_type_annotation'].size > 0}.each do |cluster|
          #      puts cluster.keys.to_json
          puts " ->cluster_ID: #{cluster['id']}"
          cat_i = list_cats.index(cluster['id'].to_s)
          puts "cat_i: #{cat_i}"
          puts " ->description: #{cluster['description']}"
          
          cluster['cell_type_annotation'].each do |annotation|
            puts " -->cell_type_annotation: #{annotation.keys.to_json}"
            puts " -->data : " + annotation['data'].to_json
            puts " -->validate_hashes : " + annotation['validate_hashes'].to_json
            puts " -->votes: " + annotation['votes'].to_json   
            
            ## create Cla if doesn't exist
            # name                    | text                        | 
            # comment                 | text                        | 
            # project_id              | integer                     | 
            # clone_id                | integer                     | 
            # annot_id                | integer                     | 
            # cell_ontology_term_json | text                        | 
            # up_gene_ids             | text                        | 
            # orcid_user_id           | integer                     | 
            # user_id                 | integer                     | 
            # cla_source_id           | integer                     | 
            # created_at              | timestamp without time zone | 
            # updated_at              | timestamp without time zone | 
            # cell_ontology_term_ids  | text                        | 
            # cat_idx                 | integer                     | 
            # cat                     | text                        | 
            # obsolete                | boolean                     | default false
            # num                     | integer                     | 
            # nber_agree              | integer                     | default 0
            # nber_disagree           | integer                     | default 0
            # down_gene_ids           | text        
            
            all_clas = Cla.where({#:annot_id => annot.id,
                                   # :cat_idx => cat_i,
                                   # :cat => cluster['id']
                                   :cell_set_id => h_cell_sets[[annot.id, cat_i]]
                                 }).all
            
            # define creator of the annotation                                                                                                                                                      
            initial_vote = annotation['votes']['votes_for']['voters'].first
            orcid_user = nil
            if initial_vote
              orcid_user = OrcidUser.where(:key => initial_vote['voter_id']).first
              if !orcid_user
                orcid_user = OrcidUser.new({:key => initial_vote['voter_id'], :name => initial_vote['voter_name']})
                orcid_user.save
            end
            end
          
            # define marker genes
            markers_ids = []
            if  annotation['data']['markers'].size > 0
              puts "Set markers!" 
              markers_ids = annotation['data']['markers'].map{|e| h_genes[e]['id']}.uniq.compact
            end
            if markers_ids.size != annotation['data']['markers'].size
              puts "Error matching genes"
              puts markers_ids.to_json
              puts annotation['data']['markers'].to_json
              exit    
            end
            
          h_cla = {
              #  :project_id => project.id,
              #  :annot_id => annot.id,
              #  :cat_idx => cat_i,
              #  :cat => cluster['id'],
              :cell_set_id => h_cell_sets[[annot.id, cat_i]],
              #          :user_id => 1,
              #   :orcid_user_id => orcid_user.id,
              #   :cla_source_id => 2,
              :name => annotation['data']['annotation_label'],
              # :up_gene_ids => markers_ids.join(","),
              :cell_ontology_term_ids => (h_cots[annotation['data']['obo_id']]) ? h_cots[annotation['data']['obo_id']] : nil
            }
            puts h_cla
            
            #    exit
            h_cla2 = {
              :project_id => project.id,
              :annot_id => annot.id,
              :cat_idx => cat_i,
              :cat => cluster['id'],
              :cell_set_id => h_cell_sets[[annot.id, cat_i]],
              :orcid_user_id => (orcid_user) ? orcid_user.id : nil,
              :cla_source_id => 2,
              :name => annotation['data']['annotation_label'],
              :cell_ontology_term_ids => (h_cots[annotation['data']['obo_id']]) ? h_cots[annotation['data']['obo_id']] : nil,
              :num =>  all_clas.size + 1,
              :comment => annotation['data']['comment'],
              :nber_agree => annotation['votes']['votes_for']['voters'].size, #annotation['votes']['votes_for']['total'],
              :nber_disagree => annotation['votes']['votes_against']['voters'].size, #annotation['votes']['votes_against']['total'],
              :up_gene_ids => (markers_ids.size > 0) ? markers_ids.join(",") : nil
            }
            
          cla = Cla.where(h_cla).first
            if !cla
              puts "add cla #{h_cla.to_json}"
              cla = Cla.new(h_cla2)       
              cla.save
              #	  exit
          else
              h_cla2[:num] = all_clas.size
              cla.update_attributes(h_cla2)
            end
            
            ### add votes
            
            ["votes_for", "votes_against"].each do |vote_type|
              annotation['votes'][vote_type]['voters'].each do |vote|
                #cla_source_id int references cla_sources, --vote source                                                      
                #cla_id int references clas,
                #orcid_user_id int references orcid_users,
                #user_name text, --optional                                                    
                #user_id int references users,
                #comment text,
                #agree bool,
                
                orcid_user = OrcidUser.where(:key => vote['voter_id']).first
                if !orcid_user
                  orcid_user = OrcidUser.new({:key => vote['voter_id'], :name => vote['voter_name']})
                  orcid_user.save
                end
                
                agree = (vote_type == 'votes_for') ? true : false

                h_cla_vote = {
                  :cla_id => cla.id,
                  :orcid_user_id => orcid_user.id,
                  :user_name => vote['voter_name'],
                  :voter_key => vote['voter_hash'],              
                  :cla_source_id => 2,
                  :agree => agree
                }
                
                cla_vote = ClaVote.where(:cla_id => cla.id, :voter_key => vote['voter_hash'], :agree => agree).first
                if !cla_vote
                  #              h_cla_vote[:orcid_user_id] = orcid_user.id
                  #              h_cla_vote[:key] = vote['voter_hash']
                  cla_vote = ClaVote.new(h_cla_vote)
                  cla_vote.save
                else
                  cla_vote.update_attributes(h_cla_vote)
                end
              end
            end
          end
          #      h_nber_items[cluster['cell_type_annotation'].size]||=0
        #      h_nber_items[cluster['cell_type_annotation'].size]+=1
          
        end
        
        
        #h_cat_info = Basic.safe_parse_json(annot.cat_info_json, {})
        
        ## init h_cat_info                                                                                                                                                                    
        #   if !h_cat_info["nber_clas"]
        if Cla.where(:annot_id => annot.id).count > 0
          h_cat_info = {"nber_clas" => [], "selected_cla_ids" => []}
          list_cats.each_index do |cat_i|
            all_clas = Cla.where(:annot_id => annot.id,  :cat_idx => cat_i).all
            h_cat_info["nber_clas"][cat_i] = all_clas.size
            #   h_cat_info["selected_cla_ids"][cat_i] = ""
            selected_cla = all_clas.sort{|a, b| a.nber_agree - a.nber_disagree <=> b.nber_agree - b.nber_disagree}.last
            h_cat_info["selected_cla_ids"][cat_i] = selected_cla.id if selected_cla
          end
          #  h_cat_info["nber_clas"][cat_i] = all_clas.size + 1
          #end
          
          #all_clas = Cla.where(:annot_id => annot.id, :cat => cat, :cat_idx => cat_i).all
          # selected_cla = all_clas.sort{|a, b| a.nber_agree - a.nber_disagree <=> b.nber_agree - b.nber_disagree}.last
          
          #    h_cat_info["selected_cla_ids"][cat_i] = selected_cla.id if selected_cla
          annot.update_attributes({:cat_info_json => h_cat_info.to_json})
        end
        
        #puts clustering.keys.to_json
      end  
    end	
  
    CellSet.where(:id => annot_cell_sets.map{|e| e.cell_set_id}).all.each do |cs|
      all_clas = cs.clas
      sel_cla = all_clas.sort{|a, b| a.nber_agree - a.nber_disagree <=> b.nber_agree - b.nber_disagree}.last     
      cs.update_attributes(:nber_clas => all_clas.size, :cla_id => (sel_cla) ? sel_cla.id : nil)
    end

    puts h_nber_items.to_json
  end

end
