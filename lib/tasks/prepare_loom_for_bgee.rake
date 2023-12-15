desc '####################### prepare loom for Bgee'
task prepare_loom_for_bgee: :environment do
  puts 'Executing...'

  now = Time.now

  loom_file = "/data/asap2/bgee/ASAP41.loom"
  final_loom_file = "/data/asap2/bgee/ASAP41_final.loom"
  metadata_file = "/data/asap2/bgee/ASAP41_reannotation_ANN.txt"
  final_metadata_file = "/data/asap2/bgee/ASAP41_final_metadata.txt"
  erx_mapping_file = "/data/asap2/fca_annot_by_tissue/ERX_mapping_file.txt"

  h_erx = {}
  File.open(erx_mapping_file, 'r') do |f|
    while (l = f.gets) do
      t = l.chomp.split("\t")
      h_erx[t[1]]=t[3]
    end
  end

  #  puts h_erx.to_json
  #exit
  
  ## copy ASAP41.loom to final
  FileUtils.cp loom_file, final_loom_file

  h_to_rename = {
    'Clustering_Leiden_resolution_2.0__default__262_' => "clustering_leiden_2.0_default",
    'CellID' => 'barcodes',
    '_Protein_Coding_Content' => 'protein_coding_content',
    '_Ribosomal_Content' => 'ribosomal_content',
    '_Mitochondrial_Content' => 'mitochondrial_content',
    'annotation' => 'asap_annotation',
    'annotation__ontology_id' => 'asap_annotationId',
    'n_counts' => 'umi_nbr',
    "n_genes" => "gene_nbr",
    "scrublet__doublet_scores" => "scrublet_score",
    "scrublet__predicted_doublets" => "scrublet_call",
    "tissue" => "asap_tissue",
    "age" => "asap_age",
    "celda_decontx__contamination" => "decontX_contamination",
    "fly_genetics" => "strain"
#    "Accession" => "gene_id",
#    "Original_Gene" => "gene_name"
  }
  
  metadata_list = ['tissue', 'annotation', 'annotation__ontology_id', 'fca_id', 'n_genes'] | h_to_rename.keys

  h_annots = {}

  t_header = [] 

  File.open(metadata_file, 'r') do |f|
    header = f.gets.chomp
    t_header = header.split("\t")
    while (l = f.gets) do
      t = l.chomp.split(/\t/).map{|e| e.gsub(/^\"/, "").gsub(/\"$/, '')}
      k = (0 .. 3).map{|i| t[i]}
      h_annots[k] = {}
      (4 .. t.size-1).each do |i|
        h_annots[k][t_header[i]] = t[i]
      end
    end
  end

  h_meta={}

  puts "Extract metadata..."

  metadata_list.each do |meta_name|
    cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{final_loom_file}  -meta /col_attrs/#{meta_name}"
    puts cmd
    h_meta[meta_name] = Basic.safe_parse_json(`#{cmd}`, {})
  end
  
#  puts h_meta.keys.map{|k| h_meta[k]['values'].size}.to_json

  ## rename tsv file columns                                                                                                                                                                                          

  h_rename = {
  "tissue_UBERON_id_name" => "anatEntityName",
  "tissue_UBERON_id" => "anatEntityId",
  "cell_UBERON_id" => "cellTypeId",
  "cell_UBERON_id_name" => "cellTypeName",
#  "ERX" => "library_id",
  "ontology_age" => "stageId"
  }

#  h_add = {
#  "n_gene" => "gene_nbr"
#  }

  list_to_rename = h_to_rename.keys.sort
  
  File.open(final_metadata_file, 'w') do |f|

    f.write((['CellID', 'library_id', "stageName", "experiment_id"] + list_to_rename.map{|e| h_to_rename[e]} + (4 .. t_header.size-1).map{|i| (h_rename[t_header[i]]) ? h_rename[t_header[i]] : t_header[i]}).join("\t") + "\n")
    h_meta["CellID"]['values'].each_index do |i|
      cell_id = h_meta["CellID"]['values'][i]
      erx = (h_erx[h_meta["fca_id"]['values'][i]]) ? h_erx[h_meta["fca_id"]['values'][i]] : 'NA'
      k = (0 .. 3).map{|j| h_meta[t_header[j]]['values'][i]}
      stage_name = "day #{h_meta["age"]["values"][i]} of adulthood"
      #  if  h_meta["n_genes"]["values"]		      
#      puts list_to_rename.map{|e| "#{e} : #{(h_meta[e] and h_meta[e]["values"]) ? h_meta[e]["values"][i] : 'NA'}"}.to_json
      if h_annots[k]
      t = [cell_id, erx, stage_name, "ERP129698"] + list_to_rename.map{|e| h_meta[e]["values"][i]} + (4 .. t_header.size-1).map{|j| (h_annots[k]) ? h_annots[k][t_header[j]] : 'NA'}
        f.write(t.join("\t") + "\n")
      else
        puts "ERROR!!"
      end
      #  else
    #    puts h_meta["n_genes"]["values"][0]
     #   exit
      #  end
    end
  end
  
  ## load metadata file in loom
  puts "load metadata file..."
  cmd = "java -jar lib/ASAP.jar -T ParseMetadata -col first -o /data/asap2/bgee/ASAP41_output.json -loom #{final_loom_file} -f  /data/asap2/bgee/ASAP41_final_metadata.txt  -type RAW_TEXT -header true -d '\t' -which CELL"  
  `#{cmd}`
  
  ## rename metadata
  puts "renaming metadata..."
  # dataset    /col_attrs/Barcode
  # dataset    /col_attrs/CellID
  # dataset    /col_attrs/age
  # dataset    /col_attrs/annotation
  # dataset    /col_attrs/annotation__ontology_id
  # dataset    /col_attrs/annotation_broad
  # dataset    /col_attrs/annotation_broad__ontology_id
  # dataset    /col_attrs/annotation_broad_extrapolated
  # dataset    /col_attrs/annotation_broad_extrapolated__ontology_id
  # dataset    /col_attrs/batch
  # dataset    /col_attrs/batch_id
  # dataset    /col_attrs/celda_decontx__clusters
  # dataset    /col_attrs/celda_decontx__contamination
  # dataset    /col_attrs/celda_decontx__doublemad_predicted_outliers
  # dataset    /col_attrs/cell_UBERON_id
  # dataset    /col_attrs/cell_UBERON_id_name
  # dataset    /col_attrs/comments
  # dataset    /col_attrs/dissection_lab
  # dataset    /col_attrs/fca_id
  # dataset    /col_attrs/fly_genetics
  # dataset    /col_attrs/id
# dataset    /col_attrs/leiden
  # dataset    /col_attrs/log_n_counts
  # dataset    /col_attrs/log_n_genes
  # dataset    /col_attrs/n_counts
  # dataset    /col_attrs/n_genes
  # dataset    /col_attrs/note
  # dataset    /col_attrs/number_of_cells
  # dataset    /col_attrs/ontology_age
  # dataset    /col_attrs/ontology_annotation
  # dataset    /col_attrs/ontology_tissue
# dataset    /col_attrs/percent_mito
  # dataset    /col_attrs/sample_id
  # dataset    /col_attrs/scrublet__doublet_scores
  # dataset    /col_attrs/scrublet__predicted_doublets
  # dataset    /col_attrs/scrublet__predicted_doublets_based_on_10x_chromium_spec
  # dataset    /col_attrs/sex
  # dataset    /col_attrs/tissue
  # dataset    /col_attrs/tissue_UBERON_id
  # dataset    /col_attrs/tissue_UBERON_id_name
  # dataset    /col_attrs/uberon_ontology_annotation
  # dataset    /col_attrs/uberon_ontology_tissue
# dataset    /col_attrs/warning
  
  
  h_rename.each_key do |k|
    #-loomFrom %s    [Required] Loom file to read from.
    #-loomTo %s      [Required] Loom file to add the metadata to.
    #-meta %s        [Required or -metaJSON] Full path of the metadata to copy.
    #-metaJSON %s    [Required or -meta] JSON file containing full path of metadata(s) to copy.
    #-o %s   [Optional] Output JSON file containing metadata that were actually copied.
    #    cmd = "java -jar lib/ASAP.jar -T CopyMetaData -loomFrom #{final_loom_file} -loomTo #{final_loom_file} -meta /col_attrs/#{k}"
    #    `#{cmd}`
    #-loom %s        [Required] Loom file to modify.
    #-meta %s        [Required or -metaJSON] Full path of the metadata to remove.
    cmd = "java -jar lib/ASAP.jar -T RemoveMetaData -loom #{final_loom_file} -meta /col_attrs/#{k}"
    puts cmd
    `#{cmd}`
  end
  
  to_delete = ["Barcode", "ClusterID", "Clustering_Annotation", "Clustering_Annotation__Relaxed_", "Clustering_Broad_Annotation", "Clustering_Broad_Annotation_Extrapolated", "Clustering_Broad_Annotation__Relaxed_", "Clustering_Leiden_resolution_0.4", "Clustering_Leiden_resolution_0.6", "Clustering_Leiden_resolution_0.8", "Clustering_Leiden_resolution_1.0__48_", "Clustering_Leiden_resolution_1.2__83_", "Clustering_Leiden_resolution_1.4", "Clustering_Leiden_resolution_1.6__4_", "Clustering_Leiden_resolution_1.8__3_", "Clustering_Leiden_resolution_10.0", "Clustering_Leiden_resolution_12.0", "Clustering_Leiden_resolution_14.0", "Clustering_Leiden_resolution_16.0", "Clustering_Leiden_resolution_18.0", "Clustering_Leiden_resolution_2.0__default__262_", "Clustering_Leiden_resolution_20.0", "Clustering_Leiden_resolution_25.0", "Clustering_Leiden_resolution_4.0", "Clustering_Leiden_resolution_50.0", "Clustering_Leiden_resolution_6.0", "Clustering_Leiden_resolution_8.0", "R_annotation", "R_annotation__ontology_id", "R_annotation_broad", "R_annotation_broad__ontology_id", "_Depth", "_Detected_Genes", "_StableID", "annotation_broad", "annotation_broad__ontology_id", "annotation_broad_extrapolated", "annotation_broad_extrapolated__ontology_id", "celda_decontx__clusters", "celda_decontx__doublemad_predicted_outliers", "id", "leiden", "log_n_counts", "log_n_genes", "number_of_cells", "sample_id", "_Mitochondrial_Content", "scrublet__predicted_doublets_based_on_10x_chromium_spec"] | list_to_rename #| (list_to_rename - ['CellID'])
  
  to_delete.each do |e|
    cmd = "java -jar lib/ASAP.jar -T RemoveMetaData -loom #{final_loom_file} -meta /col_attrs/#{e}"
    puts cmd
    `#{cmd}`
  end
  
  
  to_delete = ["Gene", "_Biotypes", "_Chromosomes", "_StableID", "_Sum", "_SumExonLength"]
  
  to_delete.each do |e|
    cmd = "java -jar lib/ASAP.jar -T RemoveMetaData -loom #{final_loom_file} -meta /row_attrs/#{e}"
    puts cmd
    `#{cmd}` 
  end		 
  
  #  h_add.each_key do |k|
  #  
  #     cmd = "java -jar lib/ASAP.jar -T CopyMetaData -loomFrom #{final_loom_file} -loomTo #{final_loom_file} -meta /col_attrs/#{k}"
  #    `#{cmd}`
  #  end

  
  ## convert
#docker run -it --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:latest
## followed by
#Rscript -e 'library("sceasy"); loom_file <- "/data/asap2/bgee/ASAP41_final.loom"; sceasy::convertFormat(loom_file, from="loom", to="anndata", outFile="/data/asap2/bgee/ASAP41_final.h5ad")'






end   
