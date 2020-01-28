desc '####################### Get GSE'
task fix_gene_set_items: :environment do
  puts 'Executing...'

  now = Time.now

  identifiers = GeneSetItem.select("distinct identifier").where(:name => nil).all #.map{|e| e.identifier}
  
  h_gsis_by_identifier = {}
  all_gsis = GeneSetItem.where(:identifier => identifiers).all
  all_gsis.map{|e| 
    h_gsis_by_identifier[e.identifier]||=[]; 
    h_gsis_by_identifier[e.identifier].push e.name
  } 

    puts "update gene set items..."
  ActiveRecord::Base.transaction do
    
    identifiers.each do |e|   
      h_gsis_by_identifier.each_key do |e|
        gsis =  h_gsis_by_identifier[e]
        names = gsis.uniq.compact
        if names.size == 1
          puts "replace all #{e} names to #{names.first}..."
          #        GeneSetItem.where("identifier = '#{e}' and name is null").update_all(:name => names.first)
        end
        #   end
      end
    end
  end

  puts "Download GO file..."
  go_file = "/data/asap2/go.obo"
  download_cmd = "wget -O #{go_file} http://purl.obolibrary.org/obo/go.obo"
  `#{download_cmd}`
  
  puts "Parse GO OBO file..."
  h_names = {}
  cur = {}
  File.open(go_file, 'r') do |f|
    while (l = f.gets) do
      l.chomp!
      if l.match(/^\[Term\]/)
        cur = {}
      elsif m = l.match(/^id: (GO:\d+)$/)
        cur[:identifier] = m[1]
      elsif m = l.match(/^name: (.+?)$/)
        cur[:name] = m[1]     
        h_names[cur[:identifier]] = m[1]
      elsif m = l.match(/^alt_id: (.+?)$/)
        h_names[m[1]] = cur[:name] 
      end      
    end
  end
  
  identifiers = GeneSetItem.select("distinct identifier").where(:name => nil).all.map{|e| e.identifier}    
  
   ActiveRecord::Base.transaction do
    
    identifiers.each do |e|
      if h_names[e]
        puts "replace all #{e} names to #{h_names[e]}..."
        GeneSetItem.where("identifier = '#{e}' and name is null").update_all(:name => h_names[e])                                                                                                           
      else
        puts "#{e} has no name."
      end
    end
  end

end
