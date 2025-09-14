desc '####################### Clean'
task check_ontology_terms: :environment do
  puts 'Executing...'
  
  now = Time.now
  
  def find_preferred_ontology_terms_with_mapping(list_cats, selected_cell_ontology_ids)
    # 1. Ensure we have valid inputs to prevent errors                                                                                                                                                        
    return {} if list_cats.blank? || selected_cell_ontology_ids.blank?
    
    # 2. Build a database-specific ORDER BY clause for custom sorting                                                                                                                                         
    order_clause = selected_cell_ontology_ids.map.with_index do |id, index|
      "WHEN #{id.to_i} THEN #{index}"
    end.join(' ')
    sql_order_statement = "CASE cell_ontology_id #{order_clause} END"
    puts "SQL ORDER: " + sql_order_statement if list_cats.include? 'epithelial cell'
    # 3. Build and execute the combined query, sorted by our preference                                                                                                                                       
    base_query = CellOntologyTerm.where(cell_ontology_id: selected_cell_ontology_ids)

    all_matches_sorted = base_query
                           .where(name: list_cats, original: true)
                           .or(base_query.where(identifier: list_cats))
                           .order(Arel.sql(sql_order_statement))

    # 4. Process sorted results to get the first unique match for each search term.                                                                                                                           
    # The `result_map` will store our final 'input' => 'record' mapping.                                                                                                                                      
    result_map = {}

    # Create a set of remaining search terms for efficiency.                                                                                                                                                  
    # This avoids repeatedly searching the original list_cats array.                                                                                                                                          
    remaining_terms = Set.new(list_cats)

    all_matches_sorted.each do |cot|
      # Stop iterating if we have found a match for every single search term.                                                                                                                                 
      break if remaining_terms.empty?

      # Check if the record's name matches a term we are still looking for.                                                                                                                                   
      if remaining_terms.include?(cot.name)
        result_map[cot.name] = cot
        remaining_terms.delete(cot.name) # We found it, so don't look for it again.
      end

      # Check if the record's identifier matches a term we are still looking for.                                                                                                                             
      if remaining_terms.include?(cot.identifier)
        result_map[cot.identifier] = cot
        remaining_terms.delete(cot.identifier) # We found it, so don't look for it again.
      end
    end

    # 5. Return the hash map directly.                                                                                                                                                                        
    return result_map
  end
  
  h_co = {}
  CellOntology.all.map{|e| h_co[e.id.to_s] = e}
  
  Project.where("public_id is not null").all.each do |p|
    
    #create table ot_projects(
    #id serial,
    #ontology_term_type_id int references ontology_term_types,
    #project_id int references projects,
    #cell_ontology_term_id int references cell_ontology_terms,
    #annot_id int references annots,
    #free_text text,
    #created_at timestamp,
    #updated_at timestamp,
    #primary key (id)
    #);
    
    organism = p.organism
    
    h_otts = {}
    OntologyTermType.all.each do |ott|
      cell_ontology_ids = ott.cell_ontology_ids.split(",")
      h_otts[ott.id] = cell_ontology_ids.map{|e| h_co[e]}.select{|e|
        if e.tax_ids and e.tax_ids != ''
          e.tax_ids.split(",").include?(organism.tax_id.to_s)
        else
          true
        end
      }.map{|e| e.id}
    end
    
    ##      cell_ontology_ids = ott.cell_ontology_ids.split(",")
    #     cell_ontologies = CellOntology.where(:id => cell_ontology_ids).all
    #     selected_cell_ontologies = cell_ontologies.select{|e|
    #       if e.tax_ids and e.tax_ids != ''
    #         e.tax_ids.split(",").include?(organism.tax_id)
    #       else
    #         true
    #       end
    #     }
    #
    #      selected_cell_ontology_ids = selected_cell_ontologies.map{|e| e.id}

    puts "PROJECT_KEY: #{p.key}"
    
    OtProject.where(:project_id => p.id).all.each do |ot_project|
      
      ot = ot_project.cell_ontology_term
      selected_cell_ontology_ids =  h_otts[ot_project.ontology_term_type_id]#.map{|e| e.id}
      if ot
        h_cots = find_preferred_ontology_terms_with_mapping([ot.name], selected_cell_ontology_ids)
        if h_cots.values.size > 0 and v = h_cots.values.first and ot.identifier != v.identifier
          puts ot.to_json
          puts "=>"
          puts h_cots.to_json
          puts "\n"
          ot_project.update_column(:cell_ontology_term_id, v.id)
        end
      end
    end
    
  end
  
end
