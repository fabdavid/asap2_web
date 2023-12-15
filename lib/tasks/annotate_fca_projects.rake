desc '####################### Annotate FCA projects'
task annotate_fca_projects: :environment do
  puts 'Executing...'

  now = Time.now

  require 'mechanize'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])


  #get mapping FBbt on UBERON
  mapping_url = "https://raw.githubusercontent.com/FlyBase/drosophila-anatomy-developmental-ontology/master/fbbt-mappings.sssom.tsv"
  ontology_mapping_file = data_dir + 'ontologies' + 'fbbt-mappings.sssom.tsv'
  cmd = "wget -O #{ontology_mapping_file} #{mapping_url}"
  `#{cmd}`

h_mapping_uberon ={}  
  File.open(ontology_mapping_file, 'r') do |f|
    while (l = f.gets) do
      t = l.chomp.split("\t")
      if t.size == 5
        h_mapping_uberon[t[0]] = t[3]
      end
    end
  end

#  puts h_mapping_uberon.to_json
puts h_mapping_uberon["FBbt:00003154"].to_json
#exit

  h_co = {}
  h_uberon = {}
  fly_ontologies = CellOntology.where(:tax_ids => "7227").all
  uberon =  CellOntology.where(:tag => "UBERON").first
  CellOntologyTerm.where(:cell_ontology_id => fly_ontologies.map{|e| e.id}).all.select{|o| o.name}.map{|o| h_co[o.name.downcase] = o}

  CellOntologyTerm.all.select{|o| o.name}.map{|o| h_co[o.name.downcase] ||= o }

   CellOntologyTerm.where(:cell_ontology_id => uberon.id).all.select{|o| o.name}.map{|o| h_uberon[o.name.downcase] = o}

  #cell_ontologies.each do |co|
  #end


  annot_by_tissue_dir = data_dir + 'fca_annot_by_tissue'
  Dir.mkdir(annot_by_tissue_dir) if !File.exist? annot_by_tissue_dir
  
  #  url = "https://www.ebi.ac.uk/biostudies/arrayexpress/studies/E-MTAB-10519/sdrf"
  url = "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB45570&result=read_run&fields=study_accession,sample_accession,experiment_accession,run_accession,tax_id,scientific_name,fastq_ftp,submitted_ftp,sra_ftp&format=json&download=true&limit=0"
  
  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body
  list = JSON.parse(data)
  
  h_erx_by_sample_name = {}
  list.each do |e|
    files = e['submitted_ftp'].split(";")
    files.each do |file|
      f = File.basename(file) #Pathname.new(file).last
      puts e['experiment_accession'] + ": " + f
      if m = f.match(/^(FCA\d+).+?(_S\d+)?(_L\d+)?\.bam.*$/)
      if ! h_erx_by_sample_name[m[1]]
        h_erx_by_sample_name[m[1]] = e['experiment_accession'] 
      elsif h_erx_by_sample_name[m[1]] !=  e['experiment_accession']
     puts "ERROR!!!"
      end
      end
    end
  end

  puts h_erx_by_sample_name.to_json

#  exit

  erx_mapping_file =  annot_by_tissue_dir + "ERX_mapping_file.txt"  
  f_erx_mapping_file = File.open(erx_mapping_file, 'w')
  f_erx_mapping_file.write ["ASAP_ID", "FCA_ID", "tissue", "ERX"].join("\t") + "\n"

  h_tissues_by_fca_id = {}

  projects = Project.where("name ~ 'FCA' and name ~ 'Stringent' and name ~ '10x' and public = true").all
  puts projects.size

  metadata_list = ['CellID', 'tissue', 'annotation', 'annotation__ontology_id', 'age']

  projects.each do |p|
    puts "ASAP" +  p.public_id.to_s + ": " + p.name
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    loom_file = project_dir + 'parsing/output.loom'
    cmd = "java -jar lib/ASAP.jar -T ListMetadata -f #{loom_file}"	    
    h_res = Basic.safe_parse_json(`#{cmd}`, {})
    h_meta = {}
    if h_res['metadata']			    
      h_meta_by_names = {}
      h_res['metadata'].select{|e| e['on'] == 'CELL'}.map{|e| h_meta_by_names[e['name']] = 1}
     
      metadata_list.each do |meta_name|
        #        if h_meta_by_names["/col_attrs/" + meta_name]
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file}  -meta /col_attrs/#{meta_name}" 
        h_meta[meta_name] = Basic.safe_parse_json(`#{cmd}`, {})
        #          if  h_meta[meta_name]['values']
        #            puts h_meta[meta_name]['values'].map{|e| e}.uniq
        #          end
        #        end
        
        
      end
      
      ## create index for tissue -> annotation
    
      if h_meta['tissue']['values'] and h_meta['annotation']['values']
        h_ind = {}
        h_meta['tissue']['values'].each_index do |i|
          annotation_ontology_id = (h_meta['annotation__ontology_id']['values']) ? h_meta['annotation__ontology_id']['values'][i].strip : 'NA'
	  age = h_meta['age']['values'][i].strip
          tissue = h_meta['tissue']['values'][i].strip
          annotation = h_meta['annotation']['values'][i].strip
          #	  erx = (m = h_meta['CellID']['values'][i].match(/(FCA\d+.+?)$/)) ?  h_erx_by_sample_name[m[1]] : 'NA'          	  
          #        h_ind[erx] ||={}
          h_ind[tissue] ||={}
          h_ind[tissue][age] ||= {}
          h_ind[tissue][age][annotation] ||= {}
          h_ind[tissue][age][annotation][annotation_ontology_id] ||= 0
	  h_ind[tissue][age][annotation][annotation_ontology_id] += 1 
        end
      end	

      ## write the index

      index_file = annot_by_tissue_dir + "ASAP#{p.public_id}.txt"
   
      File.open(index_file, 'w') do |f|
        f.write ["tissue", "age", "annotation", "annotation__ontology_id", "ontology_tissue", "uberon_ontology_tissue", "ontology_age", "ontology_annotation", "uberon_ontology_annotation", "number_of_cells"].join("\t") + "\n"
#        h_ind.each_key do |erx|
          h_ind.each_key do |tissue|
            h_ind[tissue].each_key do |age|
              h_ind[tissue][age].each_key do |annot|
                h_ind[tissue][age][annot].each_key do |annot_onto_id|                  
                  onto_tissue = (o = h_co[tissue.downcase]) ? o.identifier : 'NA'
                uberon_tissue = (o = h_uberon[tissue.downcase]) ? o.identifier : 'NA'
                uberon_tissue = h_mapping_uberon[onto_tissue] if h_mapping_uberon[onto_tissue]
                puts "uberon_tissu: #{uberon_tissue}" if onto_tissue == 'FBbt:00003154'
                  onto_age = (o = h_co["day #{age} of adulthood"]) ? o.identifier : 'NA'
                  onto_annot = (o = h_co[annot.downcase]) ? o.identifier : 'NA'
                uberon_annot =  (o = h_uberon[annot.downcase]) ? o.identifier : 'NA'
                uberon_annot = h_mapping_uberon[onto_annot] if h_mapping_uberon[onto_annot]
#oenocyte        5       adult heart     FBbt:00003154   -FBbt:00004995- CL:0000487      FBdv:00007080   FBbt:00003154   UBERON:0015230  20

                  f.write [tissue, age, annot, annot_onto_id,  onto_tissue, uberon_tissue, onto_age, onto_annot, uberon_annot,  h_ind[tissue][age][annot][annot_onto_id]].join("\t") + "\n"
                end
              end
            end
 #         end
        end
      end

      ## check erx
      h_fcas = {}
      h_meta['CellID']['values'].each_index do |i|
        cell_id =  h_meta['CellID']['values'][i]
        if m = cell_id.match(/(FCA\d+).+?$/)
          h_fcas[m[1]] = 1 #h_erx_by_sample_name[m[1]]
          tissue = h_meta['tissue']['values'][i].strip
          h_tissues_by_fca_id[m[1]] ||= {}
#          puts tissue + ":" + m[1]
          h_tissues_by_fca_id[m[1]][tissue] = 1
        end
      end

      ## write erx
      h_fcas.each_key do |k|
        tissues =  (h_tissues_by_fca_id[k]) ? h_tissues_by_fca_id[k].keys.join(",") : 'NA'
        f_erx_mapping_file.write ["ASAP#{p.public_id}", k, tissues, h_erx_by_sample_name[k]].join("\t") + "\n"
      end
  
    end
    
  end
  
   f_erx_mapping_file.close
  
end
