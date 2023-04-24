desc '####################### Execute get_ensembl_species'
task :get_ensembl_species, [:run_id] => [:environment] do |t, args|
  puts 'Executing...'
  
  data_dir = Pathname.new("/data/asap2/ensembl_species")

  vertebrate_file = data_dir + "Species.csv"
  other_species_file = data_dir + "Species2.csv"
  
  `wget -O #{other_species_file} ftp://ftp.ensemblgenomes.org/pub/release-46/species.txt`
  `dos2unix #{other_species_file}`
  #get list of species: https://www.ensembl.org/info/about/species.html
  
  `wget -O #{vertebrate_file} ftp://ftp.ensembl.org/pub/release-99/species_EnsemblVertebrates.txt`
  `dos2unix #{vertebrate_file}`
  
  require 'csv'

  [other_species_file, vertebrate_file].each do |file|

    data = CSV.read(file, { :col_sep => "\t" })
    
    #delete header
    data.shift
    
    data.each do |r|
      puts r.to_json    
      common_name = r[0]
      last_part_common_name = common_name.split(" ").last.downcase.gsub(/[^\w\d]/, '')
      db_name = r[1].downcase.gsub(" ", "_")
      db_name_full = [db_name, last_part_common_name].join("_")
      
      if !organism = Organism.where(:ensembl_db_name => db_name_full).first
        organism = Organism.where(:ensembl_db_name => db_name).first
        if organism
          puts "Found #{db_name}"
          h_organism = {}
          h_organism[:tax_id] = r[3] if !organism.tax_id
          h_organism[:name] = r[1].gsub("_", " ").capitalize if !organism.name
          h_organism[:short_name] = r[0] if !organism.short_name
          h_organism[:created_at] = Time.now if !organism.created_at
          organism.update_attributes(h_organism)
          #        puts "update #{h_organism.to_json}"
        else
          puts "!!!!!!!!! NOT FOUND #{db_name_full} !!!!!!!!"
        end
      else 
        puts "Found #{db_name_full}"
      end
    end
  end
end
