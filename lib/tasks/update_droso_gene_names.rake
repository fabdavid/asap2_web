desc '####################### Update droso gene names'
task update_droso_gene_names: :environment do

  puts 'Executing...'
  
  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  start = Time.now

  #  url = "ftp://ftp.flybase.org/releases/FB2020_03/precomputed_files/genes/gene_snapshots_fb_2020_03.tsv.gz"
  #  url = "ftp://ftp.flybase.org/releases/FB2020_06/precomputed_files/genes/gene_snapshots_fb_2020_06.tsv.gz"
  url = "ftp://ftp.flybase.org/releases/current/precomputed_files/genes/automated_gene_summaries.tsv.gz"
#  puts url  
  sum = `wget -qO - '#{url}' | zcat | head` #.force_encoding('iso-8859-1').encode('utf-8')
#puts "FIRST LINE"
#puts sum #.split(/[\r\n]+/).join(",")
  if l = sum.split("\n").first and  m = l.match(/^\#\# FlyBase automated gene summaries (\d+_\d+)/)
    puts "Version: #{m[1]}"
    url = "ftp://ftp.flybase.org/releases/FB2021_05/precomputed_files/genes/gene_snapshots_fb_#{m[1]}.tsv.gz"

    cmd = "wget -qO - '#{url}' | zcat"
    
    res = `#{cmd}`
    
    res.split("\n").each do |l|
      t = l.split("\t")
      # puts t.to_json
      #    puts t[0] + " => " +  t[2] if t.size > 2
      genes =  Gene.where(:ensembl_id => t[0]).all
      if genes.size == 1
        genes.each do |gene|
          if gene
            gene.update_attributes({:description => (t[2] == '-') ? '\\N' : t[2], :function_description => (t[2] == '-') ? '\\N' : t[4]})
            if gene.name != t[1]
              alt_names = (gene.alt_names) ? gene.alt_names.split(",") : []
              puts alt_names.to_json
              alt_names |= [gene.name]
              gene.update_attributes(:name => t[1], :alt_names => alt_names.join(","))
              puts "Add new name #{t[1]} and add alt_name #{gene.name} => #{alt_names} "
            end
          end
        end
      else
        puts "More than one gene with this ensembl-id!"
      end
    end
    
    output_json = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + 'tool_versions.json'
    
    h_tool_versions = Basic.safe_parse_json(output_json, {})

    h_tool_versions['flybase_genes'] = m[1] 
    puts h_tool_versions.to_json
    File.open(output_json, 'w') do |f|
      f.write(h_tool_versions.to_json)
    end
    
  end	
  
end
