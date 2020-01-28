desc '####################### Clean'
task compute_go_lineage: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null

  h_go_db_names = {'biological_process' => 'GO Biological Processes', 'cellular_component' => 'GO Cellular Components', 'molecular_function' => 'GO Molecular Functions'}

  def add_lineage tmp, cur_id, h_go
    if h_go[cur_id] and h_go[cur_id][:is_a].size > 0
      h_go[cur_id][:is_a].each do |k|
  #    puts "add #{k} -> #{tmp.to_json}..."
        tmp.push k if !tmp.include? k
       	tmp = add_lineage(tmp, k, h_go)
      end
    end
    return tmp
  end
  
  #load in memory adjacency tables                                                                                                                                                     
  h_go = {}
#  h_adj = {}                                                                                                                                                                          
  
  url = "http://purl.obolibrary.org/obo/go.obo"
  `wget -O ./tmp/go.obo #{url}`
  cur = {:is_a => [], :lineage => []}
  File.open("./tmp/go.obo", "r") do |f|
    while (l = f.gets) do
      if m = l.match(/^id\: (GO\:\d+)/)
        cur[:id] = m[1]
      elsif m = l.match(/^namespace\: (.+)/)
#        cur[:namespace] = m[1]
	cur[:db_name] = h_go_db_names[m[1]]
      elsif  m = l.match(/^name\: (.+)/)
        cur[:name] = m[1]
      elsif  m = l.match(/^is_a\: (GO\:\d+)/)
        cur[:is_a].push m[1]
      elsif l.chomp == '[Term]'
        if cur[:is_a] and cur[:is_a].size > 0
          h_go[cur[:id]] = cur
        end
        cur = {:is_a => [], :lineage => []}
      end
    end
  end
  
  puts "#{h_go.keys.size} go terms loaded"
  puts "adding lineage recursively..."
  h_go.keys.each do |k|
    #  puts k    
    h_go[k][:lineage] = add_lineage([], k, h_go)
    #    puts "Result: " + h_go[k][:linage].to_json
  end
  
  ## write lineage
  puts "write GO..."
  File.open("#{APP_CONFIG[:data_dir]}/go.json", 'w') do |f|
    f.write(h_go.to_json)
  end

end
