desc '####################### Fix gene enrichment results'
task fix_ge_results: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  start = Time.now

  genes = Basic.sql_query2(:asap_data, 5, 'genes', '', 'ensembl_id, name, alt_names, description', "organism_id = 35")
  h_genes = {}
  genes.each do |g|
    h_genes[g.ensembl_id] = g.description
  end	     

  Project.where(:version_id => 5, :organism_id => 35).all.each do |p|

    if p.archive_status_id == 3
      p.unarchive
    end

    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + p.user_id.to_s + p.key
    de_dir = project_dir + 'de'
    p.runs.select{|r| r.status_id == 3 and r.step.name == 'de'}.each do |r|
      output_txt = de_dir + r.id.to_s + 'output.txt'
      puts output_txt
      if File.exist? output_txt
        new_data = []
        data = File.read(output_txt)
	data.split("\n").each do |e|
          t = e.split("\t")
          t[4] = h_genes[t[1]]
          new_data.push t.join("\t")
	end		      	
 #       puts new_data.join("\n")
	File.open(output_txt, 'w') do |f|
          f.write(new_data.join("\n"))
	end		      
        puts output_txt + " found"
      end
    end
    
  end
  
end
