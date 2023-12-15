desc '####################### Fix DE results'
task fix_de_results: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  start = Time.now

#  genes = Basic.sql_query2(:asap_data, 5, 'genes', '', 'ensembl_id, name, alt_names, description', "organism_id = 35")
#  h_genes = {}
#  genes.each do |g|
#    h_genes[g.ensembl_id] = g.description
#  end	     

  Project.all.each do |p|

    if p.archive_status_id == 3
      p.unarchive
    end

    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + p.user_id.to_s + p.key
    de_dir = project_dir + 'de'
    p.runs.select{|r| r.status_id == 3 and r.step.name == 'de'}.each do |r|
      output_txt = de_dir + r.id.to_s + 'output.txt'      
      new_output_txt = de_dir + r.id.to_s + 'output.txt.old'
      if File.exist? output_txt
        FileUtils.move output_txt, new_output_txt
        #       puts "move #{output_txt} #{new_output_txt}"
      end
      up =  de_dir + r.id.to_s + 'filtered.up.json'
      new_up = de_dir + r.id.to_s + 'filtered.up.json.old'	
      if File.exist? up
        FileUtils.move up, new_up
        #      puts "move #{up} #{new_up}"
      end
      down =  de_dir + r.id.to_s + 'filtered.down.json'
      new_down = de_dir + r.id.to_s + 'filtered.down.json.old'
      if File.exist? down
        FileUtils.move down, new_down
        #          puts "move #{down} #{new_down}"
      end
      
    end
    
  end
  
end
