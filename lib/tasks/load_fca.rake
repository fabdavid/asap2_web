desc '####################### Load FCA'
task load_fca: :environment do
  puts 'Executing...'

  now = Time.now

  filepath = "/data/asap2/fca_list_projects_2.txt"

  fca_provider = Provider.find_by_tag('FCA')
  
  header = [:name, :technology, :tissue, :age, :sex, :num_samples, :version, #:loom, :h5ad, :scope, :asap, :cellxgene, 
  :loom_url, :h5ad_url, :scope_url, :asap_url, :cellxgene_url]

  attrs = {:pipeline => {:label => 'Pipeline'}, :technology => {:label => 'Technology'}, :tissue => {:label => 'Tissue'}, :age => {:label => 'Age'}, :sex => {:label => 'Sex'}, :num_samples => {:label => '# samples'}, :loom => {:label => 'FCA Loom'}}

  fca_provider.update_attribute(:attrs_json, attrs.to_json)

  list = []
  t = File.readlines(filepath).map{|l| l.chomp!; h = {}; 
    t2 = l.split("\t")
    t2.each_index do |i| 
      h[header[i]] = t2[i]  
    end
    list.push h
  }

  puts list.to_json

  list.each do |h|
  
    if h[:asap_url]
      if m = h[:asap_url].match(/ASAP(\d+)/) and n = h[:loom_url].match(/^https:\/\/cloud.flycellatlas.org\/index.php\/s\/(.+)/)
      puts h.to_json
        asap_public_id = m[1]
        puts "ASAP public ID: " + asap_public_id 
        #	puts h.to_json
        
        project = Project.where(:public_id => asap_public_id).first
        puts "PROJECT #{project.key} #{project.name}"
       
        h_metadata = {}
        attrs.each_key do |k|
          h_metadata[k] = h[k] if h[k] != 'n.a.'
        end
puts "JSON: " + h_metadata.to_json
        if h[:name].match(/Scanpy/)
          h_metadata[:pipeline] = "<a href='https://scanpy.readthedocs.io/en/stable/'>Scanpy</a>"
        end	
        if h[:name].match(/VSN/)
          h_metadata[:pipeline] = "<a href='https://github.com/vib-singlecell-nf/vsn-pipelines/'>VSN</a>"
        end
        
	h_metadata[:loom] = "<a href='" + fca_provider.url_mask.gsub(/\#\{id\}/, n[1])  + "'>Download</a>"
        
        name =  h[:name].gsub(/Scanpy /, '').gsub(/VSN /, '')
        
        h_pp = {
          :provider_id => fca_provider.id,
          :key => n[1],
          :title => name,
          :attrs_json => h_metadata.to_json
        }

        pp = ProviderProject.where({:provider_id => fca_provider.id, :key => n[1]}).first
	if !pp
          pp = ProviderProject.new(h_pp)
          pp.save
        else
          pp.update_attributes(h_pp)
	end
#        project.provider_projects.map{|pp|  project.provider_projects.delete(pp)}
        pp.projects << project if !pp.projects.include? project

        umap_annot = Annot.where(:project_id => project.id, :name => '/col_attrs/Embedding_HVG_UMAP').first
        cat_annot = nil
        if name.match(/All/)
           cat_annot = Annot.where(:project_id => project.id, :name => ['/col_attrs/annotation_broad']).first
        else
          cat_annot = Annot.where(:project_id => project.id, :name => ['/col_attrs/transf_annotation', '/col_attrs/annotation']).first
        end
        h_landing = {
          :step => 'cell_scatter',
          :s => {
            :open_controls => 1,
	    :sel_all_cats => 1,
            "s[csp_params][dim1]" => 1,
            "s[csp_params][dim2]" => 2,
            "s[csp_params][displayed_nber_dims]" => 2,
            #	    "s[store_run_id]" => umap_annot.store_run_id,
            "s[csp_params][annot_id]" => umap_annot.id,
            "s[dr_params][dot_opacity]" => 0.9,
            "s[dr_params][dot_size]" => 5,
            "s[dr_params][coloring_type]" => 3,
            "s[dr_params][cat_annot_id]" => cat_annot.id,
	    "s[dr_params][main_menu]" => "coloring",
          } 
        }

        project.update_attribute(:landing_page_json, h_landing.to_json)
	        
      end
    end
  end	    

end
