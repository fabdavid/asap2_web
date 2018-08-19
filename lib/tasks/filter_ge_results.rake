desc '####################### Parse'
task :filter_ge_results, [:project_key, :ge_id] => [:environment] do |t, args|
  puts 'Executing...'
  
  now = Time.now
  
  puts args[:project_key]
  
  project = Project.where(:key => args[:project_key]).first
  gene_enrichments= (args[:ge_id]) ? GeneEnrichment.where(:id => args[:ge_id]).all.to_a : project.gene_enrichments
  h_ge_filters = JSON.parse(project.gene_enrichment_filter_json)
  
  ### change parameters                                                                                                                                                                           
  gene_enrichments.each do |ge|
  
    filename = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key + 'gene_enrichment' + ge.id.to_s + ("output.json")

    if File.exist? filename
      
      filename_out = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key + 'gene_enrichment' + ge.id.to_s + ("output_filtered.json")
      results = JSON.parse(File.read(filename))
      new_results = {}
      
      counts = 0
      list_keys = ["p_value", "adj_p_value","OR","pathways","descriptions","urls"]
      other_keys = ["error", "warning"]
      
      list_keys.each do |k|
        new_results[k]=[]
      end
      
      other_keys.each do |k|
        new_results[k] = results[k]
      end
      
      results['adj_p_value'].each_index do |i|
        if results['adj_p_value'][i].abs <= h_ge_filters['fdr_cutoff'].to_f
          #Math.log2(h_de_filters['fc_cutoff'].to_f) 
          #          if results['FDR'][i] <= h_de_filters['fdr_cutoff'].to_f
          counts+=1
          list_keys.each do |k|
            new_results[k].push(results[k][i])
          end
          # end
          #  else
          #    break
        end
        # end
        File.open(filename_out, "w") do |f|
          f.write(new_results.to_json)
        end
      end
      ge.update_attributes(:nber_pathways => counts)
    end
  end
  
  #  @project.update_attribute(:diff_expr_filter_json, params[:filter].to_json)
  #  @h_diff_expr_filters = params[:filter]
end
