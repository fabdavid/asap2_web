desc '####################### Update from_flybase'
task update_from_flybase: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null


  latest_ensembl_release = Gene.where(:organism_id => 35).all.map{|g| g.latest_ensembl_release}.max
  
  puts "Latest ensembl release : " + latest_ensembl_release.to_s

#  exit

  start = Time.now
  
  output_json = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + 'tool_versions.json'
  h_tool_versions = Basic.safe_parse_json(output_json, {})
  
  # get equivalence identifiers
  h_identifiers = {}
  url = "ftp://ftp.flybase.org/releases/current/precomputed_files/genes/fbgn_annotation_ID.tsv.gz"
  # url = "ftp://ftp.flybase.org/releases/FB2020_04/precomputed_files/genes/fbgn_annotation_ID.tsv.gz"
  cmd = "wget -qO - '#{url}' | zcat"
  res = `#{cmd}`
  
  res.split("\n").select{|l| !l.match(/^\s*\#/) and !l.empty?}.each do |l|
    t = l.split("\t")
    #puts t.to_json
    h_identifiers[t[2]] = t[3].split(",")
  end 
  
  puts h_identifiers.to_json
  #exit

  h_biotypes = {
    "miRNA_gene" => "miRNA",
    "non_protein_coding_gene" => "ncRNA",
    "protein_coding_gene" => "protein_coding",
    "pseudogene_attribute" => "pseudogene",
    "rRNA_gene" => "rRNA",
    "snRNA_gene" => "snRNA",
    "snoRNA_gene" => "snoRNA",
    "tRNA_gene" => "tRNA"
  }

  h_data = {}

  url = "ftp://ftp.flybase.org/releases/current/precomputed_files/genes/fbgn_fbtr_fbpp_expanded_fb_#{h_tool_versions['flybase_genes']}.tsv.gz"
  cmd = "wget -qO - '#{url}' | zcat"
  res = `#{cmd}`
  res.split("\n").select{|l| !l.match(/^\s*\#/) and !l.empty?}.each do |l|
    t = l.split("\t")
    h_data[t[2]]||={}
    h_data[t[2]][:biotype] = h_biotypes[t[1]]
    h_data[t[2]][:name] = t[3]
    h_data[t[2]][:description]= t[4]
  end

  url = "ftp://ftp.flybase.org/releases/current/precomputed_files/genes/gene_map_table_fb_#{h_tool_versions['flybase_genes']}.tsv.gz"
  cmd = "wget -qO - '#{url}' | zcat"
  res = `#{cmd}`
  res.split("\n").select{|l| !l.match(/^\s*\#/) and !l.empty?}.each do |l|
    t = l.split("\t")
    if t[5]
      h_data[t[2]]||={}
      if m = t[5].match(/^(\w+)\:(\d+)\.\.(\d+)/)
        h_data[t[2]][:chr] = m[1]
        h_data[t[2]][:gene_length] = m[3].to_i - m[2].to_i
        h_data[t[2]][:sum_exon_length] = h_data[t[2]][:gene_length]
      end
    end
  end

  
  #  url = "ftp://ftp.flybase.org/releases/FB2020_04/precomputed_files/genes/gene_snapshots_fb_2020_04.tsv.gz"
  url = "ftp://ftp.flybase.org/releases/current/precomputed_files/genes/gene_snapshots_fb_#{h_tool_versions['flybase_genes']}.tsv.gz"
  cmd = "wget -qO - '#{url}' | zcat"
  
  res = `#{cmd}`
  not_found = []
  res.split("\n").select{|l| !l.match(/^\#/)}.each do |l|
    t = l.split("\t")
    if t.size > 0
      h_data[t[0]]||={}
      h_data[t[0]][:name] = t[1]
      h_data[t[0]][:description] = (t[2] != '-') ? t[2] : nil
      h_data[t[0]][:function_description] = t[4]
    end
  end
  
  h_data.each_key do |ensembl_id|
    #   t = l.split("\t")
    # if h_data[ensembl_id]#t.size > 0
    #    puts t[0] + " => " +  t[2] if t.size > 2
    genes = Gene.where(:ensembl_id => ensembl_id, :organism_id => 35).all
    if genes.size == 1
      #      genes.each do |gene|
      #        if gene
      #        gene.update_attributes({:description => (t[2] == '-') ? '\\N' : t[2], :function_description => (t[2] == '-') ? '\\N' : t[4]})
      #        end
      #      end
      
    elsif genes.size == 0
      #        puts t.to_json
      not_found.push ensembl_id
      #        if !h_identifiers[t[0]] or h_identifiers[t[0]].size == 0
      
      ## add gene
      h_gene = {
        :ensembl_id => ensembl_id,	
        #            :name => h_data[ensembl_id][:name],
        :organism_id => 35,
        #            :description => t[2],
        :latest_ensembl_release => latest_ensembl_release + 1,
        #            :function_description => t[4]
      }
      h_gene.merge!(h_data[ensembl_id])
      gene = Gene.new(h_gene)
      gene.save
      puts "add new gene #{gene.to_json}"
      #        else
      #          existing_genes = Gene.where(:ensembl_id => h_identifiers[t[0]], :organism_id => 35).all
      ##          puts existing_genes.to_json
      #          if existing_genes.size == 1
      #            existing_genes.each do |g|
      #              alt_names = g.alt_names.split(",")
      #              alt_names.push(t[0]) if !alt_names.include? t[0]
      #              #        g.update_attribute(:alt_names, alt_names.join(","))
      #              puts "add #{t[0]} to #{g.ensembl_id}"
      #            end		
      #          else
      #            puts "More than one gene for #{t[0]}!"
      #         end
      #       end
    else
      #  puts "More than one gene with this ensembl-id!"
    end
  #end
  end
  
  puts "#{not_found.size} genes not found:" +  not_found.join(", ")
  
  #not_found.each do |e|
  #alt_names = e.alt_names.split(",")
  #alt_names.push(e)
  #e.update_attribute(:alt_names => alt_names.join(","))
  
  #end
  
end
