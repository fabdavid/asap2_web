desc '####################### load ontology terms'
task load_ontologies: :environment do
  puts 'Executing...'
  
  now = Time.now
  
  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  ontology_dir = data_dir + 'ontologies'
  owl2obo_bin = "java -jar #{data_dir + "bin" + "owl2obo.jar"}"
  
  def load_ontology_term co, h_term

    if h_term['id']

      t = h_term['id'].split(":")
      if t.size == 1
        t =  h_term['id'].split("_")
      end
      original = (t[0] == co.tag) ? true : false

      puts "alt_id => " + h_term['alt_id'].to_json
      if original == false and h_term['alt_id']
        replace = nil
        h_term['alt_id'].each do |e|
          t2 = e.split(":")
          if t[0] == co.tag
            original = true
            replace = e
            puts "replace ID with #{e}"
            break
          end
        end
        if replace
          index = h_term['alt_id'].index(replace)
          h_term['alt_id'][index] = h_term['id']
          h_term['id'] = replace
          puts "effectively replaced: #{h_term.to_json}"
        end
      end

      if co.tag == 'EFO' and m = h_term['id'].match(/^efo\:EFO_(.+)/)
        h_term['alt_id'] = [h_term['id']]
        h_term['id'] = "EFO:" + m[1]
      end
      
      #  h_term[]
      h_co_term = {
        :cell_ontology_id => co.id,
        #        :latest_version => co.latest_version,
        :alt_identifiers => (h_term['alt_id']) ? h_term['alt_id'].join(",") : nil,
        :identifier => h_term['id'],
        :name => h_term['name'],
        :description => (h_term['def']) ? h_term['def'].gsub(/^\"(.+?)\".+/, '\1') : nil,
        :comment =>  (h_term['comment']) ? h_term['comment'].gsub(/^\"(.+?)\".+/, '\1') : nil,
        :content_json => h_term.to_json,
        :original => original,
        :tax_id => h_term['tax_id']
        #  :related_term_ids => '' 
      }
      
      cot = CellOntologyTerm.where(:cell_ontology_id => co.id, :identifier => h_term['id']).first
      if !cot
        h_co_term[:latest_version] = co.latest_version
        puts "New #{h_co_term.to_json}"

      #        exit
        cot = CellOntologyTerm.new(h_co_term)
        cot.save
      else
        h_existing_cot = {
          :cell_ontology_id => cot.cell_ontology_id,
          :alt_identifiers => cot.alt_identifiers,
          :identifier => cot.identifier,
          :name => cot.name,
          :description => cot.description,
          :comment => cot.comment,
          :original => cot.original,
          :tax_id => cot.tax_id
        }
        
        if h_co_term != h_existing_cot
          puts "Update with #{h_co_term.to_json}"
          cot.update_attributes(h_co_term)
        else
          puts "No need to update"
        end
      end
    end 
  end

  output_json = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + 'tool_versions.json'
  
  h_tool_versions = Basic.safe_parse_json(output_json, {})
  
  #  filename = Pathname.new(APP_CONFIG[:data_dir]) + "hcao" + "hcao.obo"
  #  CellOntology.where(:tag => 'FBdv').all.each do |co|
  CellOntology.where(:obsolete => false).order("id desc").all.each do |co|
    ## download file
    ori_file = ontology_dir + "#{co.id}.#{co.format}"
    cmd = `wget -O #{ori_file} '#{co.file_url}'`
    `#{cmd}`
    
    obo_file = ori_file
    if co.format == 'owl'
      obo_file = ontology_dir + "#{co.id}.obo"
      cmd = "#{owl2obo_bin} -i #{ori_file} -o #{obo_file}"
      `#{cmd}`
    end
    
    h_term = {}
    h_new_tool_versions = {}
    #relationship: develops_from FBbt:00000091 ! pole bud
    #relationship: expresses http://flybase.org/reports/FBgn0283442 ! vasa
    #relationship: part_of FBbt:00005311 ! stage 5 embryo
    #relationship: part_of FBbt:00005317 ! gastrula embryo
    #relationship: part_of FBbt:00005321 ! extended germ band embryo
    #relationship: part_of FBbt:00005331 ! dorsal closure embryo
    #relationship: part_of FBbt:00005333 ! late embryo

    potential_date_fields = ['date', 'remark', 'data-version']
    single_fields = ['id', 'name', 'def', 'namespace', 'comment']
    multiple_fields = ['synonyms', 'alt_id', 'is_a', 'part_of', 'disjoint_from']
    flag_term = 0
    
    File.open(obo_file) do |f|
      while (l = f.gets) do
        l.chomp!
        t = l.split(/\: /)
        if co.tag == 'CVCL' and m = l.match(/^name:(.+)/)
          t = ['name', m[1]]
        end
    
        if potential_date_fields.include?(t[0]) and !h_new_tool_versions[co.tag] and  m = t[1].match(/(\d+)[\:\-](\d+)[\:\-](\d+)/)
          if m[3].to_i > 2000
            h_new_tool_versions[co.tag] = "#{m[3]}-#{m[2]}-#{m[1]}" #t[1].gsub(/\d+\:\d+\:\d+(.+)/, '')
          elsif m[1].to_i > 2000
            h_new_tool_versions[co.tag] = "#{m[1]}-#{m[2]}-#{m[3]}"
          else
            puts "ERROR! #{t[1]} is not recognized as a date"
          end
          if h_new_tool_versions[co.tag]
            co.update_attributes(:latest_version => h_new_tool_versions[co.tag])
          end
        #          date: 26:03:2020  
        elsif t[0] == 'data-version' and m = t[1].match(/(\d+)-(\d+)-(\d+)/) and m[1].to_i > 2000
          h_tool_versions[co.tag] = "#{m[1]}-#{m[2]}-#{m[3]}"
        elsif l == "" and h_term != {}
          load_ontology_term(co, h_term)# if h_term['id'].match(/^efo/) 
          h_term = {}
          flag_term = 0
        elsif l == '[Term]'
          flag_term = 1
        elsif flag_term == 1		  
          if single_fields.include? t[0]
            h_term[t[0]] = (1 .. t.size-1).map{|i| t[i]}.join(": ")
          elsif m = l.match(/^relationship: (.+?) (.+?) \!/)
            h_term['relationship']||={}
            h_term['relationship'][m[1]]||=[]
            v = m[2]
            v.gsub!(/http:\/\/flybase.org\/reports\//, '')
            h_term['relationship'][m[1]].push v
          elsif (m = l.match(/^(\w+)\: (.+?) \!/) or m = l.match(/^(\w+)\: (.+)/)) and multiple_fields.include? m[1]
            h_term[m[1]]||=[]
            h_term[m[1]].push(m[2].gsub(/ \!$/, ''))
          elsif m = l.match(/NCBITaxon:(\d+)/)
            h_term['tax_id'] = m[1]
          end	
        end
      end
      
      load_ontology_term(co, h_term)
    end
    
  end

  h_new_tool_versions.each_key do |k|
    h_tool_versions[k] =  h_new_tool_versions[k]
  end
  
  puts h_tool_versions.to_json
  File.open(output_json, 'w') do |f|
    f.write(h_tool_versions.to_json)
  end
  
  
end
