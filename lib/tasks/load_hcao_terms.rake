desc '####################### load HCA ontology terms'
task load_hcao: :environment do
  puts 'Executing...'

  now = Time.now
  
  filename = Pathname.new(APP_CONFIG[:data_dir]) + "hcao" + "hcao.obo"
  
  h_term = {} 

  single_fields = ['id', 'name', 'def', 'namespace']
  multiple_fields = ['synonyms']

  def load_hcao_term h_term

  h_term[]

  end 


  File.open(filename) do |f|
    while (l = f.gets) do
      l.chomp!
      t = l.split(/\: /)
      if l == "[Term]"
      load_hcao_term(h_term) 
        h_term = {}
      elsif single_fields.include? t[0]
        h_term[t[0]] = t[1]
      elsif m = l.match(/^synonyms "(.+?)"/)
        h_term[t[0]]||=[]
        h_term[t[0]].push(m[1])
      end    
    end

    load_hcao_term(h_term)
  end
  
end
