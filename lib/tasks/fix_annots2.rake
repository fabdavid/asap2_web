desc '####################### Fix annots2'
task fix_annots2: :environment do
  puts 'Executing...'

  now = Time.now

  parsing_step = Step.find_by_name('parsing')
  h_outputs = Basic.safe_parse_json(parsing_step.output_json, {})
  
  h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.name] = dt }

  Project.order("id desc").all.each do |p|
    
    annots = p.annots
    annots.select{|a| a.step_id == 20}.each do |a|
      if a.data_type_id == nil
        puts "#{a.name} has a bad type"
        b = Annot.where(:project_id => p.id, :name => a.name).first
	if b
        puts "TO REPLACE: #{b.data_type_id}"
	a.update_attributes({:data_type_id => b.data_type_id})
        end
      end
    end
  end
  
end
