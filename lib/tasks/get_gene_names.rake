desc '####################### Update gene sets'
task get_gene_names: :environment do
  puts 'Executing...'

  now = Time.now

  genes_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'genes'
  
  Organism.all.each do |o|
    puts "=> #{o.name}..."
    
    o_name = o.name.downcase.gsub(" ", "_")

    #Ensembl Name    AltNames        Biotype GeneLength      SumExonLength   Chr
    
    Dir.chdir "/data/asap/genes/"
    cmd = "java -jar /srv/asap/lib/ASAP.jar -T CreateEnsemblDB -o /data/asap/genes/ -organism #{o_name}"
    puts cmd
    `#{cmd}`
    
  end
   
end
