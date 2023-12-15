desc '####################### Init cell sets'
task init_cell_sets: :environment do
  puts 'Executing...'

  now = Time.now

  h_users = {}
  User.all.map{|u| h_users[u.id] = u}

  h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.id] = dt}
  
  f_out = File.open("log/corrected_archive_status.log", 'w')

  #  Project.where(:public_id => '22').all.each do |p|
#  projects =  Project.all.sort.select{|p| p.project_cell_set_id == nil or p.key == 'elhaf1'} #.select{|e| e.id >= 8066}
  flag = 0
  projects =  Project.all.sort.select{|p| flag = 1 if p.key == '6oen2z'; flag==1}
  projects.sort.select{|p| p.annots.select{|a| a.dim == 1 and a.list_cat_json and a.data_type_id == 3}.map{|a| a.id}.sort != p.annot_cell_sets.map{|a| a.annot_id}.uniq.sort}.each do |p|
    
    unarchive = false

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key

    if p.archive_status_id == 3
      if File.exist? project_dir
        f_out.write(p.key)
        p.update_attribute(:archive_status_id, 1)
      else
        
        puts "Unarchiving #{p.key}..."
        Basic.unarchive(p.key)
        unarchive = true
      end
    end
    
    puts "Creating cell sets..."
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    
    ## for each file get the list of cells
    h_annots_by_path = {}
    h_file_details = {}

    if File.exist?(project_dir + 'parsing') and File.exist?(project_dir + 'parsing' + 'output.loom')

      # get cell names
      puts "get cells..."
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + 'parsing' + 'output.loom'} -meta /col_attrs/CellID"
      output = `#{cmd}`
      File.open(project_dir + 'parsing' + 'cell_ids', 'w') do |fout|
        fout.write(output)
      end
      res = Basic.safe_parse_json(output, {})
      cells = res['values']
      
      if cells and cells.size > 0
        
        dataset_md5 = Digest::SHA256.hexdigest({:cells => cells.sort}.to_json) 
        
        pc = ProjectCellSet.where(:key => dataset_md5).first
        if !pc
          pc = ProjectCellSet.new(:key => dataset_md5, :nber_cells => cells.size)
          pc.save
        else
          pc.update_attributes({:nber_cells => cells.size})
        end
        
        p.update_attributes({:project_cell_set_id => pc.id})
        
        p.annots.each do |a|
          if a.dim == 1 and a.list_cat_json and a.data_type_id == 3
            h_a = {
              :annot => a,
              :name => a.name,
              :list_cats => Basic.safe_parse_json(a.list_cat_json, []), 
              :nber_cols => a.nber_cols,
              :nber_rows => a.nber_rows,
              :data_type => (h_data_types[a.data_type_id]) ? h_data_types[a.data_type_id].name : 'NA',
              :imported => a.imported
            }
            h_annots_by_path[a.filepath]||=[]
            h_annots_by_path[a.filepath].push(h_a)
          end
          puts "#{a.name}: #{a.dim}, #{a.run_id}, #{a.store_run_id}"
          if a.dim==3 and a.run_id == a.store_run_id  and ! h_file_details[a.filepath]
            
            #        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + a.filepath} -meta /col_attrs/_StableID"
            #        res = Basic.safe_parse_json(`#{cmd}`, {})
            #        stable_ids = res['values']
            
            
            h_file_details[a.filepath] = {
              #          :file_size => File.size(project_dir + a.filepath),
              :run_id => a.run_id,
              #   :run_name =>  display_run_short_txt(r), #display_run(r, @h_steps[r.step_id], @h_std_methods[r.std_method_id]),                   
              #   :run_attrs => display_run_attrs(r, h_attrs, h_std_method_attrs, {}),
              :nber_cols => a.nber_cols, :nber_rows => a.nber_rows, :cells => cells
            }
          end
          
        end
        
        h_cell_sets = {}
        CellSet.where(:project_cell_set_id => pc.id).all.each do |cs|
          h_cell_sets[cs.key] = cs
        end
        
        h_annot_cell_sets = {}
        #  h_ac = {
        #              # :cell_set_id => cell_set.id,                                                                                                                                 
        # 
        #                   :project_id => p.id,
        #                   :annot_id => h_a[:annot].id,
        #                   :cat_idx => cat_idx
        #                 }
        AnnotCellSet.where(:project_id => p.id).all.each do |acs|
          h_annot_cell_sets[[acs.annot_id, acs.cat_idx]] = acs
        end
        
        ActiveRecord::Base.transaction do
          #    puts h_annots_by_path.to_json
          #    puts h_file_details.to_json
          
          h_annots_by_path.each_key do |path|
            
            ## get stable ids
            if File.exist?(project_dir + path)
              
              puts "get stable_ids for #{path}..."
              cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + path} -meta /col_attrs/_StableID"
              output = `#{cmd}`
              res = Basic.safe_parse_json(output,  {})
              stable_ids = res['values']
              File.open(project_dir + (path + ".stable_ids"), "w") do |fout|
                fout.write(output)
              end
              
              if stable_ids
                
                h_annots_by_path[path].each do |h_a|
                  ## checking annot 
                  puts "checking annot #{h_a[:name]}"
                  cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + path} -meta #{h_a[:annot].name}"
                  res = Basic.safe_parse_json(`#{cmd}`, {})
                  vals = res['values']
                  if vals 
                    if vals.size == stable_ids.size
                      h_cells = {}
                      #        h_md5 = {}
                      
                      ## init categories
                      h_a[:list_cats].each do |cat|
                        h_cells[cat] = []
                      end
                      vals.each_index do |i|
                        #	 puts vals[i]
                        if h_cells[vals[i]] and stable_ids[i]
                          h_cells[vals[i]].push cells[stable_ids[i]] 
                        else
                          puts "Category #{vals[i]} not found in #{h_a[:annot].name} [#{project_dir + path}]."
                        end
                      end
                      
                      ## for each category compute hash
                      #	list_md5 = []
                      h_a[:list_cats].each_index do |cat_idx|
                        cat = h_a[:list_cats][cat_idx]
                        # list_md5.push Digest::MD5.hexdigest h_cells[cat].to_json 
                        md5 = Digest::SHA256.hexdigest h_cells[cat].sort.to_json
                        
                        h_cell_set = {
                          :key => md5,            
                          :project_cell_set_id => pc.id,
                          :nber_cells => h_cells[cat].size
                        }
                        
                        #            cell_set = CellSet.where(:key => md5, :project_cell_set_id => pc.id).first
                        cell_set = h_cell_sets[md5]
                        if !cell_set
                          cell_set = CellSet.new(h_cell_set)
                          cell_set.save
                          h_cell_sets[md5] = cell_set
                          puts "Create cell set #{cell_set.id}"
                        else
                          puts "cell set #{cell_set.id} exists!"
                        end
                        
                        h_ac = {
                          # :cell_set_id => cell_set.id, 
                          :project_id => p.id,
                          :annot_id => h_a[:annot].id,
                          :cat_idx => cat_idx
                        }
                        #    ac = AnnotCellSet.where(h_ac).first
                        ac = h_annot_cell_sets[[h_a[:annot].id, cat_idx]]
                        if !ac and h_ac[:annot_id] != nil
                          h_ac[:cell_set_id] = cell_set.id
                          ac = AnnotCellSet.new(h_ac)
                          ac.save
                          h_annot_cell_sets[[h_a[:annot].id, cat_idx]] = ac
                          puts "Create annot_cell_set #{ac.id}"
                          # elsif ac.cell_set_id != cell_set
                          #   ac.update_attributes({:cell_set_id => cell_set.id})
                          #   h_annot_cell_sets[[h_a[:annot].id, cat_idx]]= ac
                          # puts "Update annot_cell_set #{ac.id}"
                        else
                          puts "annot_cell_set #{ac.id} exists!"
                        end
                        
                      end
                    else
                      puts "Stable IDs and metadata have not same sizes (#{stable_ids.size} vs. #{vals.size})"
                    end
                  end
                end
              end
              #        cat_info = Basic.safe_parse_json(h_a[:annot].cat_info_json, {}) 
              #        cat_info[:cell_set_md5] = 
              #        h_a[:annot].update_attribute(:cat_info, cat_info.to_json)
              
              
            end
          end  
          
        end
        
      end
    end
    
    if unarchive == true
      puts "Archiving..."
      logfile = "./log/init_cell_sets_archive.log"
      errfile = "./log/init_cell_sets_archive.err"
      cmd = "rails archive[#{p.key}] --trace 1> #{logfile.to_s} 2> #{errfile.to_s}"
      puts cmd
      `#{cmd}`
      #else
      #    puts p.archive_status_id
      #    puts unarchive.to_json
    end
#    exit

  end  
  f_out.close
  
end
