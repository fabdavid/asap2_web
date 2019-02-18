desc '####################### Get loom from HCA'
task :get_loom_from_hca, [:project_key] => [:environment] do  |t, args|
  
  require 'net/http'
  require 'net/https'

  puts 'Executing...'
  
  now = Time.now
  
  p = Project.where(:key => args[:project_key]).first
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
  h_attrs = JSON.parse(p.parsing_attrs_json)
  post_url = "https://matrix.staging.data.humancellatlas.org/v0/matrix"
  
  h_p = {
    :bundle_fqids_url => URI.encode("https://service.staging.explore.data.humancellatlas.org/manifest/files?filters=#{h_attrs['sel_hca_projects']}&format=tarball"),
    :format => "loom"
  }

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

  while(!res2['status'] or ['Failed', 'Complete'].include?(res2['status'])) do
  
    get_url =  "https://matrix.staging.data.humancellatlas.org/v0/matrix/" + h_res['request_id']	
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

  puts res2.to_json

  input_file = nil
  ### download file
  if res2['matrix_location'] and !res2['matrix_location'].empty?
    input_file = project_dir + 'input.loom'
    cmd = "wget -O #{input_file} '#{res2['matrix_location']}'"
    puts "Downloading..."
    puts cmd
    `#{cmd}`
  end	

  ### preparse file and update ncells et ngenes in the attributes
  if input_file
    cmd = "java -jar lib/ASAP.jar -T Preparsing -sel 'matrix' -organism #{p.organism_id} -f #{input_file} -o #{project_dir}"
    `#{cmd}`  
   
    
    ### get results
    h_params = JSON.parse(File.read(project_dir + "output.json"))
    
    puts h_params.to_json
    puts h_params['list_groups'][0]['nb_cells'];
    puts h_params['list_groups'][0]['nb_genes'];
    
    ### update project attributes
    ['nb_cells', 'nb_genes'].each do |k|
      h_attrs[k]=h_params['list_groups'][0][k]
    end	     
    p.update_attribute(:parsing_attrs_json, h_attrs.to_json)
    
  end
#  case res
#  when Net::HTTPSuccess, Net::HTTPRedirection
#    # OK
#  else
#    res.value
#  end
  
end

#    if p['sel_hca_projects']
#      post_url = "https://matrix.staging.data.humancellatlas.org/v0/matrix"
#      ### initialize mechanize agent                                                                                                                  
#      agent = Mechanize.new { |agent|
#        agent.user_agent_alias = 'Mac Safari'
#      }
#      h_p = {
#        :bundle_fqids_url => "https://service.staging.explore.data.humancellatlas.org/manifest/files?filters=#{p['sel_hca_projects']}&format=tarball",
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
