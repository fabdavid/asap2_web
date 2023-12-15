desc '####################### Fix annots'
task fix_annots: :environment do
  puts 'Executing...'

  now = Time.now

  parsing_step = Step.find_by_name('parsing')
  h_outputs = Basic.safe_parse_json(parsing_step.output_json, {})
  
  puts h_outputs['expected_outputs']
  h_annot_names = {}
  h_outputs['expected_outputs'].each_key do |k|
    if o = h_outputs['expected_outputs'][k] and o['dataset']
      h_annot_names[o['dataset']] = 1
    end					  
  end
  
  Project.order("id desc").all.each do |p|
    
    annots = p.annots
    annots.select{|a| a.step_id == 1}.each do |a|
    #  t = a.name.split(/\//)
      if !h_annot_names[a.name]
        puts "#{a.name} was probably imported!"
	a.update_attributes({:imported => true})
      end
    end
  end
  
end
