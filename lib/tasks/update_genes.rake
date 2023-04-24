desc '####################### Clean'
task update_genes: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  start = Time.now

  #  last_version = Version.last
  #  h_env = JSON.parse(last_version.env_json)
  #  prev_version = Version.find(last_version.id - 1)
  #  h_env_prev = JSON.parse(prev_version.env_json)
  
  def dt t, start
    d = (t - start).to_i
    #    return "#{d/60}:#{d%60}"
    Time.at(d).strftime "%H:%M:%S"
  end

  def unquote txt
    txt.strip!
    if txt[0] == "'" and txt[-1] == "'"
      txt = txt[1..-2]
    end
    return txt
  end

  def extract_genes start, db_type, release_num
    
    base_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'ensembl'
    base_dir += db_type.to_s
    Dir.mkdir base_dir if !File.exist? base_dir
    base_dir += release_num.to_s
    Dir.mkdir base_dir if !File.exist? base_dir
        
    
    h_db_types = {
      :vertebrates => {:url => "ftp://ftp.ensembl.org/pub/release-#{release_num}/mysql/"}
    }

    [:bacteria, :fungi, :metazoa, :plants, :protists].each do |tmp_db_type|
      h_db_types[tmp_db_type]= {:url => "ftp://ftp.ensemblgenomes.org/pub/release-#{release_num}/#{tmp_db_type.to_s}/mysql/"}
    end
    
    h_ensembl_subdomains = {}
    EnsemblSubdomain.all.each do |es|
      h_ensembl_subdomains[es.name.to_sym]= es
    end

    puts "#{db_type} => #{h_db_types[db_type][:url]}"
    
    base_url = h_db_types[db_type][:url] #"ftp://ftp.ensembl.org/pub/release-#{release_num}/mysql/"
    #    tmp_dir = Pathname.new("./tmp/")
    
    h_db_names = {}
    list_folders = `wget -O - #{base_url}`
    list_folders.split("\n").each do |l|
      #  puts l
      if m = l.match(/>(\w+)\/</)
        # puts m[1]
        # t = m[1].split("_")
        # t_ensembl_db_name = []
        # t.each do |w|
        #   break if w = core
        #   t_ensembl_db_name.push w
        # end
        
        #ensembl_db_name = (0 .. t.size-3).map{|i| t[i]}.join("_") 
        if m2 = m[1].match(/(.+?)_core_/)
          h_db_names[m2[1]] = m[1].strip
        end
      end
      #    puts l.chomp
    end
    
    #  puts h_db_names.to_json
    

    ensembl_tables = ['seq_region', 'gene_stable_id', 'gene', 'external_db', 'xref', 'object_xref', 'transcript', 'external_synonym', 'exon_transcript', 'exon'] 
    #, 'gene_archive', 'mapping_session']
        
#    organisms = Organism.all.to_a.select{|o| o.name and !o.name.strip.empty?}
#    organisms.each_index do |oid|
     h_db_names.keys.select{|e| !e.match(/_collection$/)}.each do |db_name| # and e.match(/drosophila_melanogaster/)}.each do |db_name|
      o = Organism.where(:ensembl_db_name => db_name).first
      if ! o
        puts "Create new organism for #{db_name}..."
        h_o = {
          :ensembl_db_name => db_name, 
          :ensembl_subdomain_id => h_ensembl_subdomains[db_type].id, 
          :latest_ensembl_release => release_num
        }
        o = Organism.new(h_o)
        o.save
      else
        o.update_attributes(
                            :ensembl_subdomain_id => h_ensembl_subdomains[db_type].id, 
                            :latest_ensembl_release => release_num
                            )
      end
      
#      ConnectionSwitch.with_db(:website_with_version, nil) do 
#        o2 = Organism.where(:ensembl_db_name => db_name).first
#        if ! o2
#          puts "Create new organism for #{db_name}..."
#          h_o = {
#            :ensembl_db_name => db_name,
#            :ensembl_subdomain_id => h_ensembl_subdomains[db_type].id,
#            :latest_ensembl_release => release_num
#          }
#          o2 = Organism.new(h_o)
#          o2.save
#        else
#          o2.update_attributes(
#                               :ensembl_subdomain_id => h_ensembl_subdomains[db_type].id,
#                               :latest_ensembl_release => release_num
#                               )
#        end
#        
#        if o2.id != o.id
#          puts "DISCREPENCY #{o.id} #{o2.id}!"
#        end
#      end
      
      #      o = organisms[oid]
      puts "#{dt(Time.now, start)}: ====> Extract #{o.ensembl_db_name} RELEASE #{release_num} #{db_type.upcase}..."
      folder_name = h_db_names[o.ensembl_db_name] #o.ensembl_db_name + '_core_97_1'
      
      if folder_name and !folder_name.empty? and !folder_name.match(/_collection$/) # and [:bacteria, :fungi, :protists].include? db_type)
        
        ## delete files if still there      
        #        ensembl_tables.each do |table_name|
        #          File.delete(tmp_dir + (table_name + ".txt")) if File.exist?(tmp_dir + (table_name + ".txt"))
        #        end
        tmp_dir = base_dir
        puts "Check archive exists: " + (tmp_dir + "#{db_name}.tgz").to_s
        puts "SIZE: " + File.size(tmp_dir + "#{db_name}.tgz").to_s if File.exist? tmp_dir + "#{db_name}.tgz"
        if !File.exist? tmp_dir + "#{db_name}.tgz" or File.size(tmp_dir + "#{db_name}.tgz") < 350
          File.delete(tmp_dir + "#{db_name}.tgz") if File.exist?(tmp_dir + "#{db_name}.tgz")
         
          tmp_dir2 = tmp_dir + db_name
          Dir.mkdir tmp_dir2 if !File.exist? tmp_dir2
          
          puts "Delete files if there are some..."                                                                                                                                                                  
          ensembl_tables.each do |table_name|                
            [".txt", ".txt.gz", ".txt.gz.bz2"].each do |ext|
              File.delete(tmp_dir2 + (table_name + ext)) if File.exist?(tmp_dir2 + (table_name + ext))                                                                                         
            end 
          end
          
          puts " - #{dt(Time.now, start)} Download tables..."
          ensembl_tables.each do |table_name|
            url = base_url + folder_name + "/" + table_name + ".txt.gz"
            
            if db_type == :vertebrates and release_num == 89
              `wget -qO #{tmp_dir2}/#{table_name}.txt.gz.bz2 '#{url}'`
              `bunzip2 #{tmp_dir2}/#{table_name}.txt.gz.bz2` if File.exist? "#{tmp_dir2}/#{table_name}.txt.gz.bz2"
            else
              `wget -qO #{tmp_dir2}/#{table_name}.txt.gz '#{url}'`
            end		 
            `gunzip #{tmp_dir2}/#{table_name}.txt.gz` if File.exist? "#{tmp_dir2}/#{table_name}.txt.gz"
            
          end
        else 
          puts "Skipping download, unzipping existing archive..."
          cmd = "cd #{tmp_dir} && tar -zxvf #{db_name}.tgz"
          `#{cmd}`
          #          ## unzip if still zipped
          #	  ensembl_tables.each do |table_name|
          #            `gunzip #{tmp_dir}/#{db_name}/#{table_name}.txt.gz` if File.exist? "#{tmp_dir}/#{db_name}/#{table_name}.txt.gz"
          #	  end		      
        end
        
        tmp_dir+= db_name
        Dir.mkdir tmp_dir if !File.exist? tmp_dir
        
        puts " - #{dt(Time.now, start)} Parse tables..."
        if File.exist? "#{tmp_dir}/xref.txt" and File.exist? "#{tmp_dir}/object_xref.txt" and File.exist? "#{tmp_dir}/gene.txt"
          
          h_external_db = {}
          File.open("#{tmp_dir}/external_db.txt", "r") do |f|
            while l = f.gets
              l = l.force_encoding('iso-8859-1').encode('utf-8')
              t = l.chomp.split("\t")
              h_external_db[t[0]] = {:priority => t[4].to_i, :cat => t[6]}
              #              end                                                                                                                                                            
            end
          end

#          puts  h_external_db.to_json
          
          h_xref = {}
          File.open("#{tmp_dir}/xref.txt", "r") do |f|
            while l = f.gets
	      l = l.force_encoding('iso-8859-1').encode('utf-8')
              t = l.chomp.split("\t")
              #              if [1100, 1300].include? t[1].to_i
              h_xref[t[0]] = {:acc => t[2], :name => t[3], :type => t[1], :description => t[5]}
              #              end
            end
          end
          
          h_object_xref = {}
          File.open("#{tmp_dir}/object_xref.txt", "r") do |f|
            while l = f.gets
              t = l.chomp.split("\t")
              if h_xref[t[3]] and ['Gene', 'Translation'].include? t[2]
                h_object_xref[t[1]] ||={}
                h_object_xref[t[1]][t[2]]||=[]
                h_object_xref[t[1]][t[2]].push(t[3])
              end
            end
          end
          
          h_seq_region = {}
          File.open("#{tmp_dir}/seq_region.txt", "r") do |f|
            while l = f.gets
              t = l.chomp.split("\t")
              h_seq_region[t[0]] = t[1]
            end
          end
          
          h_gene_stable_id = {}
          if File.exist? "#{tmp_dir}/gene_stable_id.txt"
            File.open("#{tmp_dir}/gene_stable_id.txt", "r") do |f|
              while l = f.gets
                t = l.chomp.split("\t")
                h_gene_stable_id[t[0]] = t[1]
              end
            end
          end
          
          h_gene = {}
          File.open("#{tmp_dir}/gene.txt", "r") do |f|
            while l = f.gets
              l = l.force_encoding('iso-8859-1').encode('utf-8')	
              t = l.chomp.split("\t")
              ensembl_id = nil
              description = nil
              if h_gene_stable_id[t[0]]
                ensembl_id = h_gene_stable_id[t[0]]
		description = t[10]
              else
                if db_type == :vertebrates
                  if release_num < 74
                    ensembl_id = t[14]
                    description = t[10]
                  elsif release_num > 73 and release_num < 89
                    ensembl_id = t[13]
                    description = t[10]
                  else
                    ensembl_id = t[12]
                    description = t[9]
                  end
                else
                  if release_num < 21
                    ensembl_id = t[14]
                    description = t[10]
                  elsif release_num > 20 and release_num < 37
                    ensembl_id = t[13]
                    description = t[10]
                  else 
                    ensembl_id = t[12]
                    description = t[9]
                  end
                end
              end
              description.gsub!(/\s+\[.+?\]\s*$/, '') if description

#              if description == '\\N'
#                puts "description is null"
#                if h_object_xref[t[0]]['Translation']
#                #  list_xref_ids = h_object_xref[t[0]]['Translation'].select{|e| ["2000", "2200", "2202"].include? h_xref[e][:type]}.sort{|a, b| h_xref[a][:type].to_i <=> h_xref[b][:type].to_i}
#		#  puts list_xref_ids.to_json 
#                #  xref_id = list_xref_ids.last
#		#  puts h_xref[xref_id.to_i].to_json
#		#  puts h_xref[xref_id.to_s].to_json
#                #  description = h_xref[xref_id][:description] if h_xref[xref_id]
#                else
#                  description = "" #nil
#                end
#                
#              end
              
              h_gene[ensembl_id]={
                :id => t[0], 
                :chr => h_seq_region[t[3]], 
                :biotype => t[1], 
                :gene_length => (t[5].to_i - t[4].to_i).abs + 1,
                :description => description.strip,
                :display_xref_id => t[7]
              }
            end
          end

          h_transcripts = {}
          File.open("#{tmp_dir}/transcript.txt", "r") do |f|
            while l = f.gets
	      l = l.force_encoding('iso-8859-1').encode('utf-8')
              t = l.chomp.split("\t")
              h_transcripts[t[1]]||=[]
              h_transcripts[t[1]].push t[0]
            end
          end
          
          h_exons = {}
          File.open("#{tmp_dir}/exon_transcript.txt", "r") do |f|
            while l = f.gets
              t = l.chomp.split("\t")
              h_exons[t[1]]||=[]
              h_exons[t[1]].push t[0]
            end
          end
          
          h_exon_details = {}
          File.open("#{tmp_dir}/exon.txt", "r") do |f|
            while l = f.gets
              t = l.chomp.split("\t")
              h_exon_details[t[0]]||={}
              h_exon_details[t[0]] = {:start => t[2].to_i, :end => t[3].to_i}
            end
          end
          
#          h_gene_archives = {}
#          File.open("#{tmp_dir}gene_archive.txt", "r") do |f|
#            while l = f.gets
#              t = l.chomp.split("\t")
#              h_gene_archives[t[0]] = t[7]
#            end
#          end
#          
#          h_mapping_sessions = {}
#          if File.exist? "#{tmp_dir}mapping_session.txt"
#            File.open("#{tmp_dir}mapping_session.txt", "r") do |f|
#              while l = f.gets
#                t = l.chomp.split("\t")
#                h_mapping_sessions[t[0]] = t[4]
#              end
#            end
#          end
          
          h_external_synonym = {}
          if File.exist? "#{tmp_dir}/external_synonym.txt"
            File.open("#{tmp_dir}/external_synonym.txt", "r") do |f|
              while l = f.gets
                l = l.force_encoding('iso-8859-1').encode('utf-8')
	        t = l.chomp.split("\t")
                if h_xref[t[0]] # and h_xref[t[0]][:type] == '1100'
                  h_external_synonym[t[0]]||=[]
                  h_external_synonym[t[0]].push unquote(t[1])
                end
              end
            end
          end
          
          #   puts h_gene.to_json
          #      exit
          
          i = 0      
          j = 0
          same = 0
          h_db_genes = {}
          
          #        tmp_h = {
          #              :ensembl_id => stable_id,
          #              :biotype => h_gene[stable_id][:biotype],
          ##             :chr => h_gene[stable_id][:chr],
          #             :gene_length => h_gene[stable_id][:gene_length],
          #             :organism_id => o.id,
          #             :latest_ensembl_release => release_num
          #       }
          
          #        h_ensembl_id_by_gene_id = {}
          #        h_gene_id_by_ensembl_id = {}
          #        h_new_ensembl_ids = []
          
          h_latest_ensembl_release = {}
          puts " - #{dt(Time.now, start)} Load existing genes..."
          Gene.where(:organism_id => o.id).all.each do |g| 
            h_db_genes[g.ensembl_id.downcase] = g
            #          h_ensembl_id_by_gene_id[g.id] = g.ensembl_id
            #          h_gene_id_by_ensembl_id[g.ensembl_id] = g.gene_id
            
            #          h_db_genes[g.ensembl_id] = {
            #            :ensembl_id => g.ensembl_id,
            #            :biotype => g.biotype,
            #            :chr => g.chr,
            #            :ncbi_gene_id => g.ncbi_gene_id,
            #            :gene_length => g.gene_length,
            #            :organism_id => g.organism_id,
            #            :latest_ensembl_release => g.latest_ensembl_release,
            #            :name => g.name,
            #            :sum_exon_length => g.sum_exon_length,
            #            :alt_names => g.alt_names
            #          }
          end
          
 #         if h_mapping_sessions.keys.size == 0
#          h_latest_ensembl_release[release_num]= []
 #         end
          
          puts " - #{dt(Time.now, start)} Update genes..."
          ActiveRecord::Base.transaction do
            h_gene.each_key do |stable_id|
              
              #  h_upd = {}
              # if ! h_db_genes[stable_id] #Gene.where(:ensembl_id => stable_id).first
              #   h_new_ensembl_ids.push stable_id
              #  h_db_genes[stable_id] 
              h_upd = {
                :ensembl_id => stable_id,
                :name => nil ,
                :description => h_gene[stable_id][:description],
                :biotype => h_gene[stable_id][:biotype],
                :chr => h_gene[stable_id][:chr],
                :gene_length => h_gene[stable_id][:gene_length],
                :organism_id => o.id#,
                #    :latest_ensembl_release => h_mapping_sessions[h_gene_archives[stable_id]]
              }
              
              #          h_latest_ensembl_release[stable_id] = h_mapping_sessions[h_gene_archives[stable_id]]
#              if h_mapping_sessions.keys.size > 0
#                h_latest_ensembl_release[h_mapping_sessions[h_gene_archives[stable_id]]] ||= []
#                h_latest_ensembl_release[h_mapping_sessions[h_gene_archives[stable_id]]].push(stable_id)
              #              else                
#              h_latest_ensembl_release[release_num].push(stable_id)
              #              end
              
              #  h_upd = {}
              if h_transcripts[h_gene[stable_id][:id]]
                exons = []
                #              union_pos = []
                ref_ranges = []
                h_transcripts[h_gene[stable_id][:id]].each do |t_id|
                  
                  h_exons[t_id].each do |exon_id|
                    if exon = h_exon_details[exon_id]
                      # puts exon.to_json
                      flag_ranges = []
                      ref_ranges.each_index do |ref_range_id|
                        ref_range = ref_ranges[ref_range_id]
                        if (exon[:start] < ref_range[1] and exon[:end] > ref_range[0]) or (exon[:end] > ref_range[0] and exon[:start] < ref_range[1]) 
                          flag_ranges.push ref_range_id 
                          #                        break
                        end
                      end
                      if flag_ranges.size == 1
                        ref_ranges[flag_ranges[0]][0] = exon[:start] if exon[:start] < ref_ranges[flag_ranges[0]][0]
                        ref_ranges[flag_ranges[0]][1] = exon[:end] if exon[:end] > ref_ranges[flag_ranges[0]][1]
                      elsif flag_ranges.size > 1
                        ## add new
                        starts = flag_ranges.map{|range_id| ref_ranges[range_id][0]} + [exon[:start]]
                        ends = flag_ranges.map{|range_id| ref_ranges[range_id][1]} + [exon[:end]]
                        ref_ranges.push [starts.min, ends.min]
                        ## delete existing on which it spans                 
                        flag_ranges.map{|range_id| ref_ranges.delete_at(range_id)}
                      else
                        ref_ranges.push [exon[:start], exon[:end]]
                      end
                      #                    union_pos |= (exon[:start] .. exon[:end]).to_a
                    end
                  end
                end
                #              h_upd[:sum_exon_length] = union_pos.size
                #              if ref_ranges.size > 3
                # puts stable_id
                # puts ref_ranges.to_json
                #          exit
                #              end
                h_upd[:sum_exon_length] = ref_ranges.map{|r| r[1]-r[0]+1}.sum
              end
              alt_names = []
	      if h_object_xref[h_gene[stable_id][:id]] and h_object_xref[h_gene[stable_id][:id]]['Gene']
                #            j+=1
               # alt_names = []
	   #    puts 'bla'
                hgnc_xref_id = nil
                h_object_xref[h_gene[stable_id][:id]]['Gene'].each do |xref_id|
                  if h_xref[xref_id]                    
                    if h_xref[xref_id][:type] == '1300'
                      h_upd[:ncbi_gene_id] = h_xref[xref_id][:acc].to_i
                      #   i+=1
                    elsif h_xref[xref_id][:type] == '1100'
                      hgnc_xref_id = xref_id 
                    end
                    if h_external_synonym[xref_id]
                      h_external_synonym[xref_id].each do |syn|                        
                        alt_names.push syn
                      end
                    end
                  end
                end
                #                xref_ids = h_object_xref[h_gene[stable_id][:id]]['Gene'].select{|e| h_external_db[h_xref[e][:type]][:priority]}
#                gene_name_xref_id = hgnc_xref_id
#                if !gene_name_xref_id
#                  highest_priority_xref_ids = h_object_xref[h_gene[stable_id][:id]]['Gene'].select{|e| h_xref[e] and h_external_db[h_xref[e][:type]] and h_external_db[h_xref[e][:type]][:priority#]}.sort{|a, b| h_external_db[h_xref[b][:type]][:priority] <=> h_external_db[h_xref[a][:type]][:priority]}
#                  primary_db_synonyms =  highest_priority_xref_ids.select{|e| h_external_db[h_xref[e][:type]][:cat] == 'PRIMARY_DB_SYNONYM'}
#                  gene_name_xref_id = ( primary_db_synonyms.size > 0) ? primary_db_synonyms.first : highest_priority_xref_ids.first  
#                  if stable_id == 'FBgn0263761'
#                    puts "primary:" +  primary_db_synonyms.to_json
#                    puts "highest:" + highest_priority_xref_ids.to_json
#                  end
#                end
                #elsif h_xref[xref_id][:type] == '1100'
                #	    puts "bli"
                gene_name_xref_id = h_gene[stable_id][:display_xref_id]
                if h_xref[gene_name_xref_id] and h_xref[gene_name_xref_id][:name]
                  h_upd[:name] = h_xref[gene_name_xref_id][:name].gsub(/\s+\(\s*\d+\s+of\s+\w+\s*\)/, '').strip
            #      puts "#{stable_id} : #{h_upd[:name]}\n" 
                else
                   h_upd[:name] = stable_id
#		puts "Cannot find xref for #{gene_name_xref_id}!"
# 		exit 
		end
                #             puts h_upd[:name].to_json
                #                puts "h_upd[:ensembl_id] : Highest_priority_xref_id = #{highest_priority_xref_id} -> #{h_xref[highest_priority_xref_id].to_json}"
                #                if h_external_synonym[gene_name_xref_id]
                #                  h_external_synonym[gene_name_xref_id].each do |syn|
                #                    alt_names.push syn
                #                  end
                #                end
                #                h_upd[:alt_names] = alt_names.join(",")
              end
              
              if ! h_db_genes[stable_id.downcase]
                h_upd[:alt_names] = alt_names.map{|e| e.gsub(/\s+\(\s*\d+\s+of\s+\w+\s*\)/, '').strip}.join(",")
                tmp_gene = Gene.new(h_upd)
                tmp_gene.save
                j+=1
              else
                gene_attr = h_db_genes[stable_id.downcase].attributes
                existing_alt_names = (gene_attr['alt_names']) ? gene_attr['alt_names'].split(",") : []
		existing_obsolete_alt_names = (gene_attr['obsolete_alt_names']) ? gene_attr['obsolete_alt_names'].split(',') : []                 
                h_upd[:obsolete_alt_names] = ((existing_obsolete_alt_names.map{|e| e.strip} | existing_alt_names | [gene_attr['name']]) - alt_names - [h_upd[:name]] - ['null']).compact.join(",")
#                puts "existing_alt_names " + existing_alt_names.to_json
#                puts "existing_obsolete_alt_names " + existing_obsolete_alt_names.to_json
#                puts gene_attr['name'].to_json
#                puts h_upd[:name].to_json
#                if h_upd[:name] == nil
#                  puts h_gene[stable_id][:id].to_json
#                  puts h_object_xref[h_gene[stable_id][:id]]['Gene'].to_json 
#                end
               # h_upd[:alt_names] = (((gene_attr['alt_names']) ? gene_attr['alt_names'].split(",") : []) | alt_names).join(",") if alt_names.size > 0
                h_upd[:alt_names] = alt_names.join(",")

                fields_to_check = h_upd.keys - [:ensembl_id, :organism_id]
                diff = 0
                fields_to_check.each do |field|
                  if h_upd[field] != gene_attr[field.to_s]
                    #                  puts "#{field} : #{gene_attr[field.to_s]} => #{h_upd[field]}"
                    #                  exit
                    diff = 1
                    break
                  end
                end
                if diff == 1
                  h_db_genes[stable_id.downcase].update_attributes(h_upd)
                  i+=1
                else
                  same+=1
                end
              end
              #            if h_upd.keys.size > 0
              #              #    puts h_upd.to_json
              #              #              g.update_attributes(h_upd)
              #              tmp_gene = Gene.new h_upd
              #            end          
              #   end
            end
          end ## end transaction
          
          puts " - #{dt(Time.now, start)} Update in batch the release number..."
       #   h_latest_ensembl_release.each_key do |release_num|
        #    ensembl_ids = h_latest_ensembl_release[release_num]
          ensembl_ids = h_gene.keys
          ensembl_ids.each_slice(50000) do |chunk_ensembl_ids|
            Gene.where(:ensembl_id => chunk_ensembl_ids).update_all({:latest_ensembl_release => release_num})
          end
       #   end
          
          #        ## add existing
          #
          #        print "Add existing...."
          #        existing_entries = 0
          #        h_db_genes.each_key do |stable_id|
          #          tmp_gene = Gene.new h_db_genes[stable_id]
          #          tmp_gene.save
          #          existing_entries+=1
          #        end
          #        puts "#{existing_entries} existing entries added."
          #
          #        ## add new
          #        print "Add new entries...."
          #        new_entries = 0
          #        #        h_db_genes.each_key do |stable_id|
          #        #         if !h_gene_id_by_ensembl_id[stable_id]
          #        new_ensembl_ids.each do |stable_id|
          #          tmp_gene = Gene.new h_db_genes[stable_id]
          #          tmp_gene.save
          #          new_entries+=1
          #        end
          #        puts " #{new_entries} new entries added."
          
          puts " - #{dt(Time.now, start)} RESULTS"
          puts " => #{same} genes unchanged."
          puts " => #{j} genes have been added!"
          puts " => #{i} genes have been updated!"
          puts "================================="
        else
          puts "Not found #{o.ensembl_db_name}_core"
        end
        
        #      ['gene', 'xref', 'object_xref'].each do |table_name|
        #        File.delete(tmp_dir + (table_name + ".txt")) #if File.exist?(tmp_dir + (table_name + ".txt"))
        #      end
        
        if !File.exist? base_dir + "#{db_name}.tgz"
          puts "#{dt(Time.now, start)} Zipping existing directory..."
          cmd = "cd #{base_dir} && tar -zcf #{db_name}.tgz #{db_name}"
        `#{cmd}`
        end
        if File.exist? base_dir + db_name
          puts "#{dt(Time.now, start)} Removing existing directory..."
          cmd = "cd #{base_dir} && rm #{db_name}/* && rmdir #{db_name}"
          `#{cmd}`
        end
      end
    end

     h_ensembl_subdomains[db_type].update_attribute(:latest_ensembl_release, release_num)
    
  end
  
  #  initial_release = 97
  
  #  initial_release = 99 #h_env_prev["tool_versions"]["ensembl_vertebrate"]
  initial_release = EnsemblSubdomain.where(:name => "vertebrates").first.latest_ensembl_release + 1 #Gene.maximum("release") + 1
  #  final_release = 102 #h_env["tool_versions"]["ensembl_vertebrate"]
  
  readme = `wget -O - 'http://ftp.ensembl.org/pub/current_README'`
  if m = readme.match(/Ensembl Release (\d+) Databases./)
    final_release = m[1].to_i
    if initial_release <= final_release
      puts "RELEASE update : from #{initial_release} to #{final_release}"
      
      (initial_release .. final_release).to_a.each do |release_num|
        puts "Parse Vertebrates #{release_num}..."
        extract_genes(start, :vertebrates, release_num)
      end
    else
      puts "Vertebrates is ALREADY up to date!"
    end
  end

  
  ##ensembl genomes                                                                                                                                                                                     
  #  initial_release = 46 #h_env_prev["tool_versions"]["ensembl_genomes"]

  #    final_release = 49 #h_env["tool_versions"]["ensembl_genomes"]
  [:bacteria, :fungi, :metazoa, :plants, :protists].each do |db_type|
    initial_release = EnsemblSubdomain.where(:name => db_type.to_s).first.latest_ensembl_release + 1
    
    readme = `wget -O - 'http://ftp.ensemblgenomes.org/pub/current_README'`
    if m = readme.match(/The current release is Ensembl Genomes (\d+)/)
      final_release = m[1].to_i
      if initial_release <= final_release
        
        puts "RELEASE update : from #{initial_release} to #{final_release}"
        #  exit
        (initial_release .. final_release).to_a.each do |release_num|
          puts "Parse #{db_type} #{release_num}..."
          extract_genes(start, db_type, release_num)
        end
        
      else
        puts "#{db_type.to_s.capitalize} is ALREADY up to date!"
      end
    end
  end
  
  output_json = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + 'tool_versions.json'
  
  File.open(output_json, 'w') do |f|
    f.write({"ensembl_vertebrates" => EnsemblSubdomain.find_by_name("vertebrates").latest_ensembl_release,
            "ensembl_genomes" => EnsemblSubdomain.find_by_name("bacteria").latest_ensembl_release}.to_json)
  end
  
end
