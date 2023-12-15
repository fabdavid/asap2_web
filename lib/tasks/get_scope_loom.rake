desc '####################### get scope loom'
task get_scope_loom: :environment do
  puts 'Executing...'

  now = Time.now

  require 'mechanize'

  scope_loom_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'scope'

  fca_session_id = '2c052ba9-4153-4277-afcf-e01c0609f65d_FCA'
  main_loom_files = ['20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.loom', '20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.loom']

  sub_loom_files = %w(
  20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_0.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_10.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_11.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_12.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_13.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_14.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_15.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_16.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_17.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_18.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_19.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_1.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_20.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_21.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_22.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_23.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_24.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_25.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_26.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_27.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_28.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_29.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_2.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_30.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_3.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_4.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_5.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_6.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_7.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_8.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.cluster_9.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_0.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_10.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_11.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_12.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_13.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_14.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_15.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_16.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_17.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_18.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_19.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_1.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_20.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_21.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_22.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_23.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_24.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_25.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_26.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_27.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_28.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_29.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_2.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_30.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_31.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_32.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_33.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_34.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_35.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_36.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_37.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_38.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_39.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_3.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_40.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_41.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_4.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_5.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_6.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_7.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_8.HARMONY_SCENIC.loom
20200601_FCA_BioHub_B1_B2_Head.HARMONY_SCENIC.cluster_9.HARMONY_SCENIC.loom
  )

  all_loom_files = sub_loom_files + main_loom_files

  ##download
  if 1==0	
    all_loom_files.each do |loom_file|
      cmd = "curl -F 'file-type=Loom' -F 'loomFilePath=#{fca_session_id}/#{loom_file}' scope.aertslab.org/upload/ > #{scope_loom_dir/loom_file}"
      `#{cmd}`
      ## convert
      cmd = "docker run  --name=convert_scope_loom --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v5 -c \"sh -c 'python3 convert_scope_loom.py #{scope_loom_dir/loom_file}'\""
      puts cmd
      `#{cmd}`
    end	  
  end
  
  ## reorganize files by dataset
  h_datasets = {
    :body => {:asap_project_key => '06y2o7'},
    :head => {:asap_project_key => 'kvvxcr'}
  }
  main_loom_files.each do |f|
    #20200601_FCA_BioHub_B1_B2_Body.HARMONY_SCENIC.loom
    if m = f.match(/\d+_FCA_BioHub_B1_B2_(.+?)\.HARMONY_SCENIC.loom/)
      h_datasets[m[1].downcase.to_sym][:main_loom] = f
    end
  end
  sub_loom_files.each do |f|
    if m = f.match(/\d+_FCA_BioHub_B1_B2_(.+?)\.HARMONY_SCENIC.cluster_(\d+).HARMONY_SCENIC.loom/)
      h_datasets[m[1].downcase.to_sym][:sub_looms]||={}
      h_datasets[m[1].downcase.to_sym][:sub_looms][m[2]] = f 
    end
  end
  
  puts h_datasets.to_json

  ## get clusters
  h_datasets.each_key do |d_name|
    puts "Getting clusters of #{d_name}..."
    cmd = "java -jar lib/ASAP.jar -T ListMetadata -f #{scope_loom_dir + h_datasets[d_name][:main_loom]}"
    res = `#{cmd}`
    h_res = Basic.safe_parse_json(res, {})
    #  puts h_res.to_json
#    puts h_res['metadata'].map{|e| e['name']}
    #  puts res if res.match(/default/i)
    default_clustering = h_res['metadata'].select{|e| e["name"].match(/__default__/)}.first
    puts "DEFAULT_CLUSTERING: " + default_clustering['name']

    h_subclusters = {}

    h_cells = {}

    h_datasets[d_name][:sub_looms].each_key do |cl|
    puts h_datasets[d_name][:sub_looms][cl]
      cmd = "java -jar lib/ASAP.jar -T ListMetadata -f #{scope_loom_dir + h_datasets[d_name][:sub_looms][cl]}"
      res = `#{cmd}`
      h_res = Basic.safe_parse_json(res, {})
  #    puts h_res['metadata'].map{|e| e['name']}
      default_clustering = h_res['metadata'].select{|e| e["name"].match(/__default__/)}.first
      h_res['metadata'].each do |e|
        if m = e["name"].match(/^\/col_attrs\/Clustering_Leiden_resolution_([\d.]+)/)
    #      puts "sub_clustering #{m[1]}" 
        end	
      end
     
      cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -loom #{scope_loom_dir + h_datasets[d_name][:sub_looms][cl]} -meta #{default_clustering['name']} -names"
      res = `#{cmd}`
      h_res = Basic.safe_parse_json(res, {})
   #   puts h_res.keys.to_json
     
      h_res["values"].each_index do |i|
        h_subclusters[cl + "." + h_res["values"][i]] ||= []
        h_subclusters[cl + "." + h_res["values"][i]].push h_res["cells"][i]
        h_cells[h_res["cells"][i]] = cl + "." + h_res["values"][i]
      end			 
#      puts res
    end 

    ### create file
    File.open("tmp/#{d_name}_default_scope_subclustering.txt", 'w') do |f|
      f.write("cells\tdefault_SCope_subclustering\n")
      h_cells.each_key do |k|
        f.write("#{k}\t#{h_cells[k]}\n")
      end
    end
    
 #   puts h_subclusters.keys.map{|k| "#{k} => #{h_subclusters[k].size}"}.join("\n")

  end

end

