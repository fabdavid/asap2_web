desc '####################### Update organisms'
task update_organisms: :environment do
  puts 'Executing...'

  now = Time.now


  ### create organism list

#  species_filepath = "#{APP_CONFIG[:data_dir]}/species.txt"
#  species = []

  urls = [
#    "https://ftp.ensembl.org/pub/release-113/species_EnsemblVertebrates.txt",
#    "https://ftp.ensemblgenomes.org/pub/release-60/species.txt"
    ["https://ftp.ensembl.org/pub/release-113/species_metadata_EnsemblVertebrates.json", 'vertebrates_species.json'],
    ["https://ftp.ensemblgenomes.org/pub/release-60/species_metadata.json", 'ensemblgenomes_species.json']
  ]
  
  ### Download DELETE FILES MANUALLY if you want to update

  urls.each do |url|
    filepath = Pathname.new(APP_CONFIG[:data_dir]) + "ensembl" + url[1] 
    if !File.exist? filepath
      puts "Downloading #{url[0]}..."
      `wget --no-check-certificate -O #{filepath} '#{url[0]}'`
    end
  end
  
  
  
  #name	species	division	taxonomy_id	assembly	assembly_accession	genebuild	variation	microarray	pan_compara	peptide_compara	genome_alignments	other_alignments	core_db	species_id
  #Spiny chromis	acanthochromis_polyacanthus	EnsemblVertebrates	80966	ASM210954v1	GCA_002109545.1	2018-05-Ensembl/2020-03	N	N	N	Y	Y	Y	acanthochromis_polyacanthus_core_113_1	1	
  #name text,
  #short_name text,
  #go_short_name text,
  #genrep_key text,
  #tax_id int,
  #tag text,
  #ensembl_subdomain_id int references ensembl_subdomains (id),

  h_ensembl_subdomains = {}
  EnsemblSubdomain.all.map{|e| h_ensembl_subdomains["Ensembl" + e.name.capitalize] = e.id}
  
  urls.each do |url|
 
    #    uri = URI.parse(url[0])
    #   response = Net::HTTP.get_response(uri)
    #    http = Net::HTTP.new(uri.host, uri.port)
    #    http.use_ssl = true
    #    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    #    response = http.get(uri.request_uri)
    #    puts response.code
    #    if response.code == "200"
    #      #      puts "Success! Response: #{response.body}"
    #      #      lines = response.body.split("\n")
    #      list_species = JSON.parse(response.body)
    #      list_species.each do |species|
    #  puts "LINE: " + line
    # t = line.split("\t")

    filepath = Pathname.new(APP_CONFIG[:data_dir]) + "ensembl" + url[1]
    list_species = JSON.parse(File.read(filepath))
    list_species.each do |species|
      if ["EnsemblVertebrates", "EnsemblMetazoa", "EnsemblPlants", "EnsemblProtists", "EnsemblBacteria", "EnsemblFungi"].include? species["division"]
        
        h = {
          :name => species["organism"]["scientific_name"].gsub("_", " ").capitalize,
          :short_name => species["organism"]["display_name"],
          :tax_id => species["organism"]["taxonomy_id"],
          :ensembl_subdomain_id => h_ensembl_subdomains[species["division"]],
          :ensembl_db_name => species["organism"]["name"]
        }
        
        # organism = Organism.where(:tax_id => species["organism"]["taxonomy_id"], :ensembl_db_name => species["organism"]["name"]).first
        organism = Organism.where(:ensembl_db_name => species["organism"]["name"]).first
        if !organism
#          organism = Organism.new(h)
#          organism.save
        else
          organism.update_attributes(h)
        end

      end
    end
    
    #  else
    #      puts "Cannot read this URL #{url}"
    #      exit
    #    end
    
  end
  
  
  
#  File.open(species_filepath, "w") do |f|
#    f.write species.map{|e| e.join("\t")}join("\n")
#  end

  
#  list_organisms = File.read(species_filepath).split("\n").map{|l| l.split("\t")}
#  header = list_organisms.shift
#  puts list_organisms.to_json

#  list_organisms.each do |organism_e|
#    organism_name = organism_e[0]
#    organism = Organism.where(["lower(name) = ?", organism_name.gsub("_", " ").downcase]).first
#    if organism
#      puts "Organism #{organism_name} found!"
#      if !organism.go_short_name
#        organism.update_attributes({:go_short_name => organism_e[1]})
#      end
#    else
#      puts "Organism not found"
#      t = organism_name.split("_")
#      tag =  t[0].first + t[1][0 .. 1]
#      i=1
#      while (Organism.where(:tag => tag).first) do
#        i+=1
#        tag = t[0].first + t[1][0 .. 1] + i.to_s
#      end
#      h = {
#        :name => organism_name.gsub("_", " ").capitalize,
#        :tag => tag,
#        :go_short_name => organism_e[1],
#        :short_name => organism_e[1],
#        :tax_id => organism_e[2]
#      }
#      puts h.to_json
#      organism = Organism.new(h)
#      organism.save
#    end
#  end

#puts list_organisms.map{|e| e.gsub("_", " ").capitalize}.join("','")
  
end
