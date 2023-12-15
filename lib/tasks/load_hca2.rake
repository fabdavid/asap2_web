desc '####################### Load HCA2'
task load_hca2: :environment do
  puts 'Executing...'

  now = Time.now

  # filepath = "/data/asap2/fca_projects.txt"
  
  hca_provider = Provider.find_by_tag('HCA')
  
  #  header = [:name, :technology, :tissue, :age, :sex, :num_samples, :version, :loom, :h5ad, :scope, :asap, :cellxgene, :loom_url, :h5ad_url, :scope_url, :asap_url, :cellxgene_url]

  attrs = {:link => {:label => 'HCA project page'}, :loom => {:label => 'Input file'}, :species => {:label => 'Species'},  :organs => {:label => 'Organ'}, :development_stages => {:label => "Development stage"}, :approaches => {:label => "Technology"}}

  hca_provider.update_attribute(:attrs_json, attrs.to_json)

#  nber_hits_displayed = 200
#  h_filters = {} 
#  q_txt = URI::encode(h_filters.to_json)
#  url = "https://service.azul.data.humancellatlas.org/index/projects?filters=#{q_txt}&size=#{nber_hits_displayed}&sort=projectTitle&order=asc&catalog=dcp13"
  hca_json_file = "/data/asap2/hca/projects.json"
  h_hca = {
  :projects => Basic.safe_parse_json(File.read(hca_json_file), {})
  }
  h_titles = {}
  sum_matrices = []
#  [:species, 'genusSpecies'],
#                   [:organs, 'organ'],
#                   [:development_stages, 'developmentStage'],
#                   [:approaches
  list_fields = ['genusSpecies', 'organ', 'libraryConstructionApproach', 'developmentStage']
  h_hca[:projects]['hits'].each_index do |i|
    e = h_hca[:projects]['hits'][i]
    h_matrices = e['projects'][0]['matrices']
    h_project_sum_matrices = {}
    h_cur = {}
    h_res = Basic.recursive_parse_hca list_fields, h_matrices, h_cur, h_project_sum_matrices
    sum_matrices.push h_res[:h_project_sum_matrices]
    title = e['projects'].map{|e2| e2['projectTitle']}.join(", ")
    h_titles[e["entryId"]]= title
    puts "EntryID: " + e["entryId"]
    puts "Title: " + title

    h_res[:h_project_sum_matrices].each_key do |k|
      m =  h_res[:h_project_sum_matrices][k]
      puts "Matrix: #{m.to_json}"      
      puts "create new provider_project"
#      pp = ProviderProject.where(:provider_id => 1, :key => e["entryId"]).first
      h_attrs = {
        :link => "<a href='" + hca_provider.url_mask.gsub(/\#\{id\}/, e["entryId"]) + "'>Visit</a>",
        :loom => "<a href='#{m[:url]}'>#{m[:name]}</a>",
      }
      pp = ProviderProject.where(:provider_id => 1, :key => e["entryId"], :filename => m[:name]).first

      m.each_key do |k2|
        if [:approaches, :development_stages, :organs, :species].include? k2
          h_attrs[k2] = m[k2].join(", ")
        else
          h_attrs[k2] = m[k2]
        end
      end
      #      if m[:species] != ['Homo sapiens']
      
      h_provider_project = {
        :provider_id => 1,
        :title => title,
        :filename => m[:name],
        :key => e["entryId"],
        :attrs_json => h_attrs.to_json
      }
      if !pp and h_provider_project[:filename]
        pp = ProviderProject.new(h_provider_project)
	puts pp.to_json
        pp.save
      else
        puts "UPDATE: " + h_provider_project.to_json
        pp.update_attributes(h_provider_project)
      end
    end
  end



#  pps = hca_provider.provider_projects

#  pps.each do |pp|
    
#    h_metadata = {:link => "<a href='" + hca_provider.url_mask.gsub(/\#\{id\}/, pp.key) + "'>Visit</a>"}
    #  attrs.each_key do |k|
    #    h_metadata[k] = h[k]
    #  end
#    pp.update_attribute(:attrs_json, h_metadata.to_json)       
    
#  end	    
  
end
