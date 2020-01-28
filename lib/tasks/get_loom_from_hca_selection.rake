desc '####################### Get loom from HCA'
task :get_loom_from_hca_selection, [:project_key] => [:environment] do  |t, args|
  
  require 'net/http'
  require 'net/https'

  puts 'Executing...'
  
  now = Time.now
 
  fu_dir = Pathname.new(APP_CONFIG[:upload_data_dir])
 
  p = Project.where(:key => args[:project_key]).first
 
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
  h_attrs = JSON.parse(p.parsing_attrs_json)
  post_url = "https://matrix.data.humancellatlas.org/v0/matrix"

  h_p = {
    #    :bundle_fqids_url => URI.encode("https://service.explore.data.humancellatlas.org/manifest/files?filters=#{h_attrs['sel_provider_projects']}&format=tarball"),
    :bundle_fqids_url => URI.encode("https://service.explore.data.humancellatlas.org/manifest/files?filters=#{h_attrs['sel_provider_projects']}"), 
    :format => "loom"
  }

  output_json_file = File.open(project_dir + 'parsing' + 'get_loom_from_hca.json', "w") 
  h_output = {}
  puts h_p.to_json
  uri = URI.parse(post_url)
  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
  req.body = h_p.to_json
  res = https.request(req)
  #  puts "Cookie: " + res.get_fields('set-cookie').to_json
  #  cookie = res.response['set-cookie'].split('; ')[0]
  ## 	  
  h_res =	 JSON.parse(res.body)
  
  puts res.body.to_json 
  #  exit;
  #  puts res.message
  #  puts res['request_id']
  
  res2 = {}
  
  while(!res2['status'] or !['Failed', 'Complete'].include?(res2['status'])) do
  
    get_url = "https://matrix.data.humancellatlas.org/v0/matrix/" + h_res['request_id']	
    #    puts get_url
    #    uri2 = URI.parse(get_url)						 
    #
    #    https2 = Net::HTTP.new(uri2.host,uri2.port)
    #    https2.use_ssl = true
    #    headers = {
    #      'X-API-KEY' => 'Z9rUPlwAt26XpKkHYqp3S3nVb6798au97ttzQ5VT',
    #      'Host' => '',
    #      'Content-Type' =>'application/json'
    #    }
    #    req2 = Net::HTTP::Get.new(uri.path, headers) #initheader = {'Content-Type' =>'application/json', 'X-API-KEY' => 'Z9rUPlwAt26XpKkHYqp3S3nVb6798au97ttzQ5VT'})
    #    res2 = https.request(req2)
    #    puts res2.body
    
    cmd = "wget -O - '#{get_url}'"
    res2 = JSON.parse(`#{cmd}`)
    puts res2.to_json
    sleep(30)
  end	  
  
  if res2['status'] == 'Failed'
    
    res2['message']
    h_output["error"] = res2['message']
    h_output["status_id"] = 4
    #    {"eta":"","matrix_location":"","message":"syntax error at or near \")\"\nLINE 8: ...89a-a10e-4761-9ae1-3aaadc752020.2019-04-28T130109.414000Z',)...", "request_id":"78b8b8f6-b52a-4506-959e-10f472c92411","status":"Failed"}
    
  else
    
    h_output["status_id"] = 3
    
    puts res2.to_json
    
    input_file = nil
    
    ### file is ready to download
    if res2['matrix_location'] and !res2['matrix_location'].empty?
      
      #   id | project_id | upload_type | name | status | upload_file_name | upload_content_type | upload_file_size |   
      #   upload_updated_at | visible | created_at | updated_at | project_key | user_id | url                                
      h_fu = {
        :project_id => p.id,
        :status => 'new',
        :upload_type => 1,
        :upload_file_name => "HCA_" + h_res['request_id'] + ".loom",
        :url => res2['matrix_location']
      }
      
      fu = Fu.new(h_fu)
      puts h_fu.to_json
      fu.save!
      
      puts "next"
      input_file = fu_dir + fu.id.to_s + fu.upload_file_name 
      
      ### create directory if it doesn't exist yet
      Dir.mkdir(fu_dir + fu.id.to_s) if !File.exist?(fu_dir + fu.id.to_s)
      ### delete file if it exists
      File.delete(input_file) if File.exist? input_file
      ### download file 
      cmd = "wget -O #{input_file} '#{res2['matrix_location']}'"
      puts "Downloading..."
      puts cmd
      `#{cmd}`
      
      ### delete symlink in project if it exists
      File.delete project_dir + 'input.loom' if File.exist? project_dir + 'input.loom'
      ### create symlink in project
      File.symlink input_file, project_dir + 'input.loom'
      
      ### update fu with file size
      fu.update_attributes({:status => 'downloaded', :upload_file_size => File.size(input_file)})
      
    end
    
    ### preparse file and update ncells et ngenes in the attributes
    if input_file
      cmd = "java -jar lib/ASAP.jar -T Preparsing -sel 'matrix' -organism #{p.organism_id} -f #{input_file} -o #{fu_dir + fu.id.to_s} 2>&1 > #{fu_dir + fu.id.to_s + 'preparsing.log'}"
      `#{cmd}`  
      
      ### get results
      h_params = JSON.parse(File.read(fu_dir + fu.id.to_s + "output.json"))
      
      puts h_params.to_json
      puts h_params['list_groups'][0]['nber_cols'];
      puts h_params['list_groups'][0]['nber_rows'];
      
      ### update project attributes
      ['nber_cols', 'nber_rows'].each do |k|
        h_attrs[k]=h_params['list_groups'][0][k]
      end	     
      p.update_attributes({:nber_cols => h_attrs['nber_cols'], :nber_rows => h_attrs['nber_rows'], :parsing_attrs_json => h_attrs.to_json})
      
    end
  end

  puts "H_OUTPUT:" + h_output.to_json
  output_json_file.write(h_output.to_json)

  #  case res
  #  when Net::HTTPSuccess, Net::HTTPRedirection
  #    # OK
  #  else
  #    res.value
  #  end
  
end

#    if p['sel_provider_projects']
#      post_url = "https://matrix.staging.data.humancellatlas.org/v0/matrix"
#      ### initialize mechanize agent                                                                                                                  
#      agent = Mechanize.new { |agent|
#        agent.user_agent_alias = 'Mac Safari'
#      }
#      h_p = {
#        :bundle_fqids_url => "https://service.staging.explore.data.humancellatlas.org/manifest/files?filters=#{p['sel_provider_projects']}&format=tarball",
#        :format => "loom"
#        #%7B%22file%22%3A%7B%22project%22%3A%7B%22is%22%3A%5B%22Single+cell+RNAseq+characterization+of+cell+types+produced+over+time+in+an+in+vitro+model+of+human+inhibit#ory+interneuron+differentiation.%22%2C%22Single+cell+transcriptome+analysis+of+human+pancreas%22%5D%7D%2C%22biologicalSex%22%3A%7B%22is%22%3A%5B%22male%22%5D%7D%2C%22fileFormat%22%3A%7B%22is%22%3A%5B%22matrix%22%5D%7D%7D%7D&format=tarball                        
#      }
#      h_headers = {
#        "Content-Type" => "application/json"
#      }
#      agent.post post_url, h_p, h_headers
#    end
#
#
#end
