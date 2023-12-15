desc '####################### Load old ASAP public projects'
task load_old_asap_public_projects: :environment do
  puts 'Executing...'

  now = Time.now

  cmd = "wget -O - 'https://asap-old.epfl.ch/projects.json?public_limit=200'"
  h_res = Basic.safe_parse_json(`#{cmd}`, {})

  puts  h_res

  h_res['public'].each do |e|

  last_pp = Project.where({:public => true}).order("id desc").first

    h_p = {
      :key => e['key'],
      :name => e['name'],
      :version_id => 3,
      :public => true,
      :public_id => (last_pp) ? last_pp.public_id + 1 : nil,
      :nber_cols => e['nber_cells'],
      :nber_rows => e['nber_genes'],
      :modified_at => e['updated_at'],
      :step_id => e['step_id'],
      :status_id => e['status_id'],
      :organism_id => e['organism_id'],
      :pmid => e['pmid'],
      :user_id => e['user_id']
    }
    
    p = Project.where(:key => e['key']).first
    
    if !p 
      if  h_p[:nber_cols] > 0
        puts "Create new project for key #{e['key']}..."
        puts h_p.to_json
        new_p = Project.new(h_p)
        new_p.save
      end

      else	

      h_p.delete(:public_id)
      p.update_attributes(h_p)

    end


#    if !p.modified_at
#      p.update_attribute(:modified_at, p.created_at)
#    end

  end

#Project.reindex
  
end
