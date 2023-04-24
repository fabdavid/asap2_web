module Fetch

#class Basic

  class << self

    def load_articles pmids

      ActiveRecord::Base.transaction do
        pmids.to_s.split(";").each do |pmid|
          h_article = Fetch.fetch_pubmed(pmid)
          article = Article.where(:pmid => pmid).first
          if !article
            article = Article.new(h_article)
            article.save
          else
            article.update_attributes(h_article)
          end
        end
      end
      
    end

    def add_exp_entry_identifiers(exp_entry, h_identifiers)
      h_identifiers.each_key do |k|
        h_identifiers[k].each do |identifier|
          h_eeid = {
            :exp_entry_id => exp_entry.id,
            :identifier_type_id => k,
            :identifier => identifier
          }
          ee_identifier = ExpEntryIdentifier.where(h_eeid).first
          if !ee_identifier
            ee_identifier = ExpEntryIdentifier.new(h_eeid)
            ee_identifier.save
          end
        end
      end
    end

    def add_upd_exp_codes h
      puts "LAAAAAAA"
      h_existing_exp_codes = {}
      h[:project].exp_entries.each do |exp_entry|
        h_existing_exp_codes[exp_entry.identifier_type_id] ||= {}
        h_existing_exp_codes[exp_entry.identifier_type_id][exp_entry.identifier] = exp_entry
      end
      puts "LAAAAAA" + h_existing_exp_codes.to_json
      h_code_types = {:geo_codes => 5, :array_express_codes => 6, :ega_codes => 10}
      
      h_code_types.each_key do |code_type|
        puts "BLIIII" + code_type.to_json
        h_codes = {}
        h[code_type].strip! if h[code_type]
        if h[code_type] and !h[code_type].empty?
          
          h[code_type].split(/[\s,;]+/).each do |code|
            h_codes[code] =1
            if !h_existing_exp_codes[h_code_types[code_type]] or !h_existing_exp_codes[h_code_types[code_type]][code] 
              puts("BLAAAAAAAAAAAAAA ARRAY EXPRESS" + h[code_type] + "")
              if code_type == :geo_codes
                Fetch.fetch_gse(code)
              elsif code_type == :array_express_codes
                puts("BLAAAAAAAAAAAAAA ARRAY EXPRESS")
                Fetch.fetch_array_express(code)
              end
              exp_entry = ExpEntry.where(:identifier => code, :identifier_type_id => h_code_types[code_type]).first
              if exp_entry and !h[:project].exp_entries.include? exp_entry
                h[:project].exp_entries << exp_entry if !h[:project].exp_entries.include? exp_entry
              end
            end
          end
        end
        puts ("LIIIII1" + code_type.to_s + ", " + h_existing_exp_codes[h_code_types[code_type]].to_json)
        if h_existing_exp_codes[h_code_types[code_type]]
          puts ("test delete")
          h_existing_exp_codes[h_code_types[code_type]].each_key do |code|
            if !h_codes[code]
              puts ("test delete #{code}")
              h[:project].exp_entries.delete(h_existing_exp_codes[h_code_types[code_type]][code])
            end
          end
        end
      end

    end
    
    def fetch_array_express(array_express_id)

      base_url = "https://www.ebi.ac.uk/arrayexpress/files/#{array_express_id}/#{array_express_id}"
      
      base_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'array_express'

      ## download files
      url = "#{base_url}.idf.txt"
      file = base_dir + 'idf' + (array_express_id + '.idf.txt')
      if !File.exist?(file) or File.size(file) == 0 ## NOT UPDATING BUT PREVENTING INTERRUPTION OF SERVICE FROM EBI - TO BE DELETED
        cmd = "wget -qO #{file} #{url}"
#        puts "CMD: #{cmd}"
        `#{cmd}`
      end
      
      url_samples = "#{base_url}.sdrf.txt"
      file_samples = base_dir + 'sdrf' + (array_express_id + '.sdrf.txt') ## SAME
      if !File.exist?(file_samples) or File.size(file_samples) == 0
        cmd = "wget -qO #{file_samples} #{url_samples}"
        `#{cmd}`
      end

      #Investigation Title     Single cell RNA-seq of adult human neural retina
      #Person Last Name        Lukowski        Wong
      #Person First Name       Samuel  Raymond
      #Person Mid Initials     W       CB
      #
      #Public Release Date     2019-08-21
      #PubMed ID
      #Person Email    s.lukowski@uq.edu.au    ching.wong@unimelb.edu.au
      #
      #Experiment Description  To comprehensively profile cell types in the human retina, we performed single cell RNA-sequencing on 20,009 cells obtained post-mortem from three donors and compiled a reference transcriptome atlas. Using unsupervised clustering analysis, we identified 18 transcriptionally distinct clusters representing all known retinal cells: rod photoreceptors, cone photoreceptors, M..ler glia cells, bipolar cells, amacrine cells, retinal gganglion...

      fields = ["Investigation Title", "Person Last Name", "Person First Name", "Person Mid Initials", "Person Email", "PubMed ID", "Experiment Description", "Public Release Date", "Comment [SecondaryAccession]"]
      h_fields = {}
      fields.map{|field| h_fields[field] = []}
     
      File.open(file, 'r') do |f|
        while (l = f.gets) do
          l.chomp!
          t = l.split(/\t/)
          if fields.include? t[0]
            (1 .. t.size).each do |i|
              h_fields[t[0]].push t[i]
            end
          end
        end
      end
      
   #   puts h_fields["Public Release Date"].compact.uniq.to_json

      other_identifiers = {
        2 => h_fields["Comment [SecondaryAccession]"].compact
      }

      h_exp_entry = {
        :identifier => array_express_id, 
        :identifier_type_id => 6,
        :contributors => (0 .. h_fields["Person Last Name"].size-1).map{|i| [h_fields["Person Last Name"][i], h_fields["Person Mid Initials"][i], h_fields["Person First Name"][i]].join(",")}.join(";"),
        :contact_emails => h_fields["Person Email"].join(";"),
        :title => h_fields["Investigation Title"].join(" "),
        :description => h_fields["Experiment Description"].join(" "),
        :identifiers_json => other_identifiers.to_json,
        :pmid => h_fields["PubMed ID"].join(";"),
        :submitted_at =>  h_fields["Public Release Date"].compact.uniq.map{|e| Time.new(e)}.sort.first
      }

      exp_entry = ExpEntry.where(:identifier => array_express_id).first
      if ! exp_entry
        exp_entry = ExpEntry.new(h_exp_entry)
        exp_entry.save
      else
        exp_entry.update_attributes(h_exp_entry)
      end

      Fetch.add_exp_entry_identifiers(exp_entry, other_identifiers)

      Fetch.load_articles(exp_entry.pmid)

      h_sample_identifier_types = {
        "Comment[ENA_SAMPLE]" => 3,
        "Comment[BioSD_SAMPLE]" => 7,
        "Comment[ENA_EXPERIMENT]" => 8,
        "Comment[ENA_RUN]" => 9
      }

      ## get sample identifiers
      #Source Name     Comment[ENA_SAMPLE]     Comment[BioSD_SAMPLE]   Characteristics[organism]       Characteristics[developmental stage]    Characteristics[individual]     Characteristics[replicate]      Characteristics[sex]    Characteristics[disease]        Characteristics[organism part]  Comment[cell number]    Material Type   Protocol REF    Protocol REF    Protocol REF    Extract Name    Comment[single cell isolation]  Comment[library construction]   Comment[end bias]       Comment[input molecule] Comment[primer] Comment[LIBRARY_LAYOUT] Comment[LIBRARY_SELECTION]      Comment[LIBRARY_SOURCE] Comment[LIBRARY_STRAND] Comment[LIBRARY_STRATEGY]       Comment[NOMINAL_LENGTH] Comment[NOMINAL_SDEV]   Protocol REF    Performer       Assay Name      Technology Type Comment[ENA_EXPERIMENT] Scan Name       Comment[ENA_RUN]        Comment[BAM_URI]        Comment[read1 file]     Comment[FASTQ_URI]      Comment[read2 file]     Comment[FASTQ_URI]      Comment[index1 file]    Comment[FASTQ_URI]      Protocol REF    Protocol REF    Derived Array Data File Comment [Derived ArrayExpress FTP file] Protocol REF    Protocol REF    Derived Array Data File Comment [Derived ArrayExpress FTP file] Protocol REF    Protocol REF    Derived Array Data File Comment [Derived ArrayExpress FTP file] Protocol REF    Protocol REF    Derived Array Data File Comment [Derived ArrayExpress FTP file] Factor Value[replicate]
    
      fields = []
      i=0
 #     puts "FILE: " + file_samples.to_s

      list_sample_identifiers = []
      File.open(file_samples, 'r') do |f|
        while (l = f.gets) do
          l.chomp!
          #          puts l
          t = l.split(/\t/)
          if i == 0
            fields = t
          else
            
            h_fields = {}
            fields.each_index do |j|
              h_fields[fields[j]] = t[j]
            end
            #          puts h_fields
              h_sample_identifier_types.select{|k| h_fields[k]}.each_key do |k|
              h_sample_identifier = {
                :identifier => h_fields[k],
                :identifier_type_id => h_sample_identifier_types[k]
              }
              list_sample_identifiers.push h_sample_identifier
            end
          end
          i+=1
        end
      end
      
      existing_sids = SampleIdentifier.where(:identifier => list_sample_identifiers.map{|e| e[:identifier]}).all
      h_existing_sids = {}
      existing_sids.each do |e|
        h_existing_sids[e.identifier] =e
      end
      ActiveRecord::Base.transaction do
        list_sample_identifiers.each do |h_sid|
          sample_identifier = h_existing_sids[h_sid[:identifier]]#SampleIdentifier.where(:identifier => h_fields[k]).first
          if !sample_identifier
            sample_identifier = SampleIdentifier.new(h_sid)
            sample_identifier.save
            h_existing_sids[sample_identifier.identifier] = sample_identifier
          else
            sample_identifier.update_attributes(h_sid)
          end
        end
      end
      
      h_sample_identifiers = {}
      exp_entry.sample_identifiers.map{|e| h_sample_identifiers[e.id] = 1}
      
      ActiveRecord::Base.transaction do
        h_existing_sids.each_key do |k|
          sample_identifier = h_existing_sids[k]
          exp_entry.sample_identifiers << sample_identifier if !h_sample_identifiers[sample_identifier.id] #exp_entry.sample_identifiers.include? sample_identifier
        end
      end
    end
    
    def find_gse_link agent, url, gse_code
      found = nil
      page = agent.get url
      page.links.each do |link|
        
        gse_mask = link.text[0..-2].gsub(/n/, '.')
   #   puts gse_mask
        if gse_code.match(/^#{gse_mask}$/)
    #      puts "Found #{gse_code}"
          found = link.text
        end
      end
      
      
      return {:url => url + (found || ''), :found => found}
    end
    
    def fetch_gse(gse_code)
      
      h_fields = {
        'Series_pubmed_id' => :pmid,
        'Series_summary' => :description,
        'Series_contributor' => :contributors,
        'Series_contact_email' => :contact_emails,
        'Series_submission_date' => :submitted_at
      }
      
      agent = Mechanize.new { |agent|
        agent.user_agent_alias = 'Mac Safari'
      }
      
      url = "http://ftp.ncbi.nlm.nih.gov/geo/series/"
      
      start_time = Time.now

      existing_gse = ExpEntry.where(:identifier => gse_code).first
      found_link = {}
      #   if !existing_gse
      found_link = find_gse_link(agent, url, gse_code)
      
      while (found_link[:found] and found_link[:found] != gse_code + "/") do
        found_link = find_gse_link(agent, found_link[:url], gse_code)
      end
      #   end
  #    puts "TIME: Got link after " + (Time.now-start_time).to_s
      
      h_exp_entry = {:identifier => [gse_code], :identifier_type_id => [5], :srp => []}
      sample_identifiers = []
      h_identifiers = {}

      if found_link[:found] 
        
     #   puts "Finally found URL: " + found_link[:url]
        
        matrices_url =  found_link[:url] + "matrix/"
        
        page = agent.get matrices_url
        page.links.select{|l| l.text != 'Parent Directory'}.each do |link|
     
          matrix_url = found_link[:url] + "matrix/" + link.text ##{args[:gse]}_series_matrix.txt.gz"
          gse_matrix_file = Pathname.new(APP_CONFIG[:data_dir]) + "gse" + link.text
          if !File.exist? gse_matrix_file or File.size(gse_matrix_file) == 0
            cmd = "wget -qO #{gse_matrix_file} '#{matrix_url}'"
            #  puts cmd
            `#{cmd}`
          end
           
               
          cmd = "zcat #{gse_matrix_file}"
               
          content = `#{cmd}`
          content.split(/\n/).each do |line|
            
            if m = line.match(/^\!(.+?)_(.+?)\t(.+?)$/) and m[1] and m[2] and m[3]
              
              values = m[3].split(/\t/).map{|e| e[1..-2]}
         #     puts m[1] + " : " + m[2] + " : " + values.join(";")
              
              field_name = h_fields[m[1] + "_" + m[2]] || m[2]
              
              if m[1] == 'Series'
                
                if ['contact_email', 'pubmed_id', 'title', 'summary', 'contributor', 'submission_date'].include? m[2]
                  h_exp_entry[field_name] ||= []
                  h_exp_entry[field_name].push values
                elsif ['sample_id'].include? m[2]
                  values.join(" ").split(/\s+/).each do |identifier|
                    sample_identifiers.push({:identifier_type => 'GEO Sample ID', :identifier => identifier})
                  end
                elsif m2 = line.match(/\!Series_relation\t"SRA: https.+?(SRP\d+?)"/)
                  h_exp_entry[:srp].push m2[1]
                  h_identifiers[2]||=[]
                  h_identifiers[2].push m2[1]
                elsif m2 = line.match(/\!Series_relation\t"BioProject: https.+?(PRJNA\d+?)"/)
                  h_identifiers[4]||=[]
                  h_identifiers[4].push m2[1]
                end
                
              elsif m[1] == 'Sample'
                if m[2] == 'relation'
                  values.each do |val|
                    t = val.split(/\s*\:\s+/)
                    if t[1] and m2 = t[1].match(/[\/=]([A-Z0-9]+?)$/) #and m2[1].match(/(SAMN)|(.RX)/)
                      sample_identifiers.push({:identifier_type => t[0], :identifier => m2[1]})
                    end
                  end
                end
                
              end
              
            end
          end
        
#          puts "TIME: Treat file #{gse_matrix_file.to_s} after " + (Time.now-start_time).to_s
  
        end
        
        h_exp_entry.each_key do |k|
          if k == 'submission_date'
            h_exp_entry[k] = h_exp_entry[k].flatten.uniq.map{|e| Time.new(e)}.sort.first
          else
            h_exp_entry[k] = h_exp_entry[k].flatten.uniq.join(";")
          end
        end

 #       puts "TIME: Before save " + (Time.now-start_time).to_s
        
#        puts h_exp_entry.to_json
        h_exp_entry[:identifiers_json] = h_identifiers.to_json
        exp_entry = ExpEntry.where(:identifier => h_exp_entry[:identifier]).first
        if !exp_entry
          exp_entry = ExpEntry.new(h_exp_entry)
          exp_entry.save
 #         puts "Saved!"
        else
          exp_entry.update_attributes(h_exp_entry)
  #        puts "Updated!"
        end

        Fetch.add_exp_entry_identifiers(exp_entry, h_identifiers)
        

     #   puts "TIME: After save " + (Time.now-start_time).to_s

        Fetch.load_articles(exp_entry.pmid)
        
     #   puts "TIME: After PubMed load " + (Time.now-start_time).to_s
        
        h_translate = {"GEO Sample ID" => "GEO Sample", "SRA" => "SRA Sample", "BioSample" => "BioSample"}
        
        h_identifier_types = {}
        IdentifierType.all.map{|e| h_identifier_types[e.name] = e}
        
        #   puts sample_identifiers.to_json
        ActiveRecord::Base.transaction do
          sample_identifiers.each do |si|
            identifier_type = h_identifier_types[h_translate[si[:identifier_type]]] #IdentifierType.where(:name => h_translate[si[:identifier_type]]).first
            if !identifier_type
              identifier_type = IdentifierType.new({:name => h_translate[si[:identifier_type]]})
              identifier_type.save
            end
          end
        end
        
    #    puts "TIME: After edition IdentifierType " + (Time.now-start_time).to_s
        
        h_identifier_types = {}
        IdentifierType.all.map{|e| h_identifier_types[e.name] = e}
        h_sample_identifiers = {}
        SampleIdentifier.all.map{|e| h_sample_identifiers[e.identifier] = e}
        
        ActiveRecord::Base.transaction do
          
          sample_identifiers.each do |si|
            identifier_type = h_identifier_types[h_translate[si[:identifier_type]]]
            h_sample_identifier = {
              :identifier_type_id => identifier_type.id, :identifier => si[:identifier]
            }
            sample_identifier = h_sample_identifiers[si[:identifier]] #SampleIdentifier.where(h_sample_identifier).first
            if !sample_identifier
              sample_identifier = SampleIdentifier.new(h_sample_identifier)
              sample_identifier.save
              h_sample_identifiers[sample_identifier.identifier]=sample_identifier
            end
          end
        end

    #    puts "TIME: After edition SampleIdentifier1 " + (Time.now-start_time).to_s

        h_existing_sample_identifiers = {}
        exp_entry.sample_identifiers.map{|e| h_existing_sample_identifiers[e.id] = 1}
        
        ActiveRecord::Base.transaction do
          h_sample_identifiers.each_key do |k|
            sample_identifier = h_sample_identifiers[k]
            exp_entry.sample_identifiers << sample_identifier if !h_existing_sample_identifiers[sample_identifier.id]
          end
        end
        
     #   puts "TIME: After edition SampleIdentifier2 " + (Time.now-start_time).to_s

      end
    end

    def fetch_pubmed(pmid)
      
      require 'hpricot'
      require 'open-uri'

      results = nil

      if pmid
      
      doc = open("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=#{pmid}&retmode=xml") { |f| Hpricot(f) }
      p_article = doc.at("pubmedarticle")
    
      if p_article
        citation= p_article.at("medlinecitation")
        article = citation.at("article")
        results = {:pmid => pmid}
        journal_node = article.at("journal")
        if journal_node
          journal_title = journal_node.at("title").innerHTML
          journal = Journal.where(:name => journal_title).first
          if !journal
            journal = Journal.new(:name => journal_title)
            journal.save
          end
          results[:journal_id] = journal.id
          if journal_issue = journal_node.at("journalissue")
            results[:volume] = journal_issue.at("volume").innerHTML if journal_issue.at("volume")
            results[:issue] = journal_issue.at("issue").innerHTML if journal_issue.at("issue")
            pubdate = journal_issue.at("pubdate")
            results[:year]=''
            if pubdate.at("year")
              results[:year]=pubdate.at("year").innerHTML
            elsif pubdate.at("medlinedate")
              results[:year]=pubdate.at("medlinedate").innerHTML.split(" ").first
            end
          end
        end
        results[:title]=article.at("articletitle").innerHTML
        authors = article.at("authorlist").search("author")
        all_authors = []
        authors.each do |a|
          all_authors.push(a.at("lastname").innerHTML + " " + ((a.at("initials")) ?  a.at("initials").innerHTML : ''))
        end
        results[:authors]=all_authors.join(";")
    #    results[:authors]+= " et al." if authors.size > 1
        abstract = article.at("abstract")
        results[:abstract]=abstract.at("abstracttext").innerHTML if abstract
      end

      end
      return results

    end
  end
end
