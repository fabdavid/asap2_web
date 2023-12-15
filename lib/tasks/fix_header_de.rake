desc '####################### Fix header DE'
task fix_header_de: :environment do
  puts 'Executing...'

  now = Time.now

  de_steps = Step.where(:name => 'de').all

  new_header = ["logFC", "P-value", "FDR", "Avg group1", "Avg group2"]

  Project.order("id desc").all.each do |p|
    
    p.runs.where(:step_id => de_steps.map{|s| s.id}).each do |r|
      r.annots.each do |annot|
        if annot.dim == 2 and annot.headers_json == ['Value 1', 'Value 2', 'Value 3', 'Value 4', 'Value 5'].to_json 
          puts annot.to_json
          annot.update_attributes({:headers_json => new_header.to_json})
        end
      end
    end

  end
  
end
