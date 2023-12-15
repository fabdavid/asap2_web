desc '####################### Init annotations'
task init_annotations: :environment do
  puts 'Executing...'

  now = Time.now

  h_users = {}
  User.all.map{|u| h_users[u.id] = u}

  #  Project.where(:public_id => '22').all.each do |p|
  Project.all.each do |p|


    ## get cell_sets
    h_cell_sets = {}
    annot_cell_sets = p.annot_cell_sets
    annot_cell_sets.each do |annot_cell_set|
      h_cell_sets[[annot_cell_set.annot_id, annot_cell_set.cat_idx]] = annot_cell_set.cell_set_id
    end

    p.annots.select{|a| a.dim ==1 and a.list_cat_json}.each do |a|
      puts a.id.to_s + ": " + a.name.to_s + " => " + a.list_cat_json
      list_cats =  Basic.safe_parse_json(a.list_cat_json, [])
      h_cat_aliases = Basic.safe_parse_json(a.cat_aliases_json, {}) #if a.cat_aliases_json
      sel_clas = []
      h_nber_clas = {}
      list_cats.each_index do |i|
        k = list_cats[i]
	puts h_cat_aliases.to_json
 
        sel_cla = ''
        # add automatic annotation                                                                                                                                                                                       
        annot_name = k
        annot_name.strip!
        num = 0

        if annot_name and annot_name != '' and !annot_name.match(/^-?[0-9.]+$/)
          
          puts annot_name
          cot = CellOntologyTerm.where(["(identifier = ? or name = ?) and original = true", annot_name, annot_name]).first
          puts cot.to_json
          num = 1
          cot_ids = (cot) ? cot.id : nil
          user_id = (h_cat_aliases and h_cat_aliases['user_ids'] and h_cat_aliases['user_ids'][k]) ? h_cat_aliases['user_ids'][k].to_i : a.user_id
          cell_set_id = h_cell_sets[[a.id, i]] 
          h_cla = {
            :cla_source_id => 3, #(h_cat_aliases['names'] and h_cat_aliases['names'][k]) ? 1 : 3,                                                                                                              
            :name => (cot) ? "" : annot_name, # : 1,                                                                                                    
            :annot_id => a.id,
            :num => num,
            :cat_idx => i,
            :cell_set_id => cell_set_id,
            :cell_ontology_term_ids => cot_ids,
            :cat => k, #a.name, #(cot) ? '' : k,                                                                                                
            :user_id => 1,
            #            :user_name => h_users[user_id].displayed_name,                       
            :project_id => p.id
          }
          
          h_cla2 = {
            :cell_set_id => cell_set_id,
            :cell_ontology_term_ids => cot_ids,
            :name => (cot) ? "" : annot_name            
          }

          cla = Cla.where(h_cla2).first
          if !cla
            cla = Cla.new(h_cla)
            cla.save
           end
          #  sel_clas.push cla.id                                                                                                                                                                                           
          sel_cla = cla.id
        end

        annot_name = nil
        annot_name = h_cat_aliases['names'][k] if h_cat_aliases['names'] and h_cat_aliases['names'][k] #if h_cat_aliases['names'][k] != k 
        
        annot_name.strip! if annot_name
        
        if annot_name and annot_name != '' and !annot_name.match(/^-?[0-9.]+$/)
          num+=1
          puts annot_name
          cot = CellOntologyTerm.where(["(identifier = ? or name = ?) and original = true", annot_name, annot_name]).first
          puts cot.to_json
          #	  if !cot
          #             cot = CellOntologyTerm.where(["identifier = ? or name = ?", annot_name, annot_name]).first
          #          end	
          #          HsapDv:0000087
          cot_ids = (cot) ? cot.id : nil
          user_id = (h_cat_aliases and h_cat_aliases['user_ids'] and h_cat_aliases['user_ids'][k]) ? h_cat_aliases['user_ids'][k].to_i : a.user_id
          h_cla = {
            :cla_source_id => 1, #(h_cat_aliases['names'] and h_cat_aliases['names'][k]) ? 1 : 3,          
            :name => (cot) ? "" : annot_name, # : 1,
            :annot_id => a.id,
	    :num => num,
            :cat_idx => i,
            :cell_ontology_term_ids => cot_ids,
            :cat => k, #a.name, #(cot) ? '' : k,
            :user_id => (h_cat_aliases['names'] and h_cat_aliases['names'][k]) ? user_id : 1,
            #            :user_name => h_users[user_id].displayed_name,
            :project_id => p.id
          }

          h_cla2 = {
            :cell_set_id => cell_set_id,
            :cell_ontology_term_ids => cot_ids,
            :name => (cot) ? "" : annot_name
          }

          cla = Cla.where(h_cla2).first
          if !cla	
            cla = Cla.new(h_cla)
            cla.save
          end        
          #  sel_clas.push cla.id
          sel_cla = cla.id
          
          #          if cla.cla_source_id == 1
          
            ## add vote 
          h_cla_vote = {
            :cla_source_id => 1, #(p.name.match(/HCA/)) ? 3 : ((p.name.match(/FCA/)) ? 2 : 1),
            :cla_id => cla.id,
            :user_name => (user_id == 1) ? 'admin' : h_users[user_id].displayed_name, #user.email.split(/@/).first,
            :user_id => user_id,
            :comment => '',
            :agree => true
          }
          
          cla_vote = ClaVote.where(h_cla_vote).first
          if !cla_vote
            cla_vote = ClaVote.new(h_cla_vote)
            cla_vote.save
          end
          
          ## update nber_votes            
          cla.update_attributes({:nber_agree => 1})
          #         end
          
        end
        
        
        sel_clas.push sel_cla
        h_nber_clas[i] = Cla.where(:annot_id => a.id,
                                     :num => 1,
				     :cat_idx => i, 
                                     :project_id => p.id
                                   ).count
      end
      
      h_cla_sum = {
        :nber_clas => (0 .. list_cats.size-1).to_a.map{|i| (sel_clas[i] == '') ? 0 : h_nber_clas[i]},
        :selected_cla_ids => sel_clas
      }
      
      a.update_attributes({:cat_info_json => h_cla_sum.to_json})
      
    end
  end
  
end
