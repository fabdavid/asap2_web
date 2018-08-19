desc '####################### Parse'
task :filter_de_results, [:project_key, :de_id] => [:environment] do |t, args|
  puts 'Executing...'
  
  now = Time.now
  
  puts args[:project_key]
  
  project = Project.where(:key => args[:project_key]).first
  diff_exprs= (args[:de_id]) ? DiffExpr.where(:id => args[:de_id]).all.to_a : project.diff_exprs
  h_de_filters = JSON.parse(project.diff_expr_filter_json)

  puts "Filter with: " + h_de_filters.to_json
  
  list_keys = ["logFC", "pval", "FDR", "AvCountG1", "AvCountG2", "AvNormG1", "AvNormG2", "text"]
  other_keys = ["error", "warning"]

  ### change parameters                                                                                                                                                                           
  diff_exprs.each do |de|
    h_counts = {}
    ['up', 'down'].each do |type|
      filename = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key + 'de' + de.id.to_s + ("output." + type + ".json")
      filename_out = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key + 'de' + de.id.to_s + ("output." + type + "_filtered.json")
      
      if File.exist? filename  
        results = JSON.parse(File.read(filename))
        new_results = {}	       
        list_keys.each do |k|
          new_results[k]=[] if results[k]
        end
        other_keys.each do |k|
          new_results[k] = results[k] if results[k]
        end
        h_counts[type] = 0
        results['logFC'].each_index do |i|
          if results['logFC'][i].abs >= Math.log2(h_de_filters['fc_cutoff'].to_f) 
            if results['FDR'][i] <= h_de_filters['fdr_cutoff'].to_f
              h_counts[type]+=1
              new_results.keys.each do |k|
                new_results[k].push(results[k][i])
              end
            end
          else
            break
          end
        end
        File.open(filename_out, "w") do |f|
          f.write(new_results.to_json)
        end
      end
      de.update_attributes(:nber_up_genes => h_counts['up'], :nber_down_genes => h_counts['down'])
    end

  end
  
  #  @project.update_attribute(:diff_expr_filter_json, params[:filter].to_json)
  #  @h_diff_expr_filters = params[:filter]
end
