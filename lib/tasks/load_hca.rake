desc '####################### Load HCA'
task load_hca: :environment do
  puts 'Executing...'

  now = Time.now

 # filepath = "/data/asap2/fca_projects.txt"

  hca_provider = Provider.find_by_tag('HCA')
  
#  header = [:name, :technology, :tissue, :age, :sex, :num_samples, :version, :loom, :h5ad, :scope, :asap, :cellxgene, :loom_url, :h5ad_url, :scope_url, :asap_url, :cellxgene_url]

  attrs = {:link => {:label => 'HCA project page'}}

  hca_provider.update_attribute(:attrs_json, attrs.to_json)

  pps = hca_provider.provider_projects

  pps.each do |pp|
    
    h_metadata = {:link =>  "<a href='" + hca_provider.url_mask.gsub(/\#\{id\}/, pp.key)  + "'>Visit</a>"}
  #  attrs.each_key do |k|
  #    h_metadata[k] = h[k]
  #  end
    pp.update_attribute(:attrs_json, h_metadata.to_json)       
    
  end	    
  
end
