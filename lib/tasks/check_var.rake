desc '####################### Check var'
task check_var: :environment do
  puts 'Executing...'

  now = Time.now

#  parsing_step = Step.find_by_name('parsing')
#  h_outputs = Basic.safe_parse_json(parsing_step.output_json, {})
  
#  puts h_outputs['expected_outputs']
#  h_annot_names = {}
#  h_outputs['expected_outputs'].each_key do |k|
#    if o = h_outputs['expected_outputs'][k] and o['dataset']
#      h_annot_names[o['dataset']] = 1
#    end					  
#  end
  
  h_steps = {}
  Step.all.map{|s| h_steps[s.id] = s}
  
  h_std_method_attrs = {}
  h_outputs = {}

#  h_std_methods = {}
#  StdMethod.where(:obsolete => false).all.each do |std_method|
#    h_std_methods[std_method.id] = std_method
#    h_res = Basic.get_std_method_attrs(std_method, h_steps[std_method.step_id])
#    h_std_method_attrs[std_method.id] = h_res[:h_attrs]
##    h_std_method_attrs[std_method.id].each_key do |k|
#    #      puts "DATASET: " + h_std_method_attrs[std_method.id][k]['dataset'].to_json
##    end
#  end

  Step.all.each do |step|
    h_outputs[step.id] = Basic.safe_parse_json(step.output_json, {})    
  end

  h_var = {}

  h_outputs.each_key do |step_id|
    if  h_outputs[step_id]['expected_outputs']
      h_outputs[step_id]['expected_outputs'].each_key do |k|
#        puts k
        h_outputs[step_id]['expected_outputs'][k].each_key do |k2|
          
          v = h_outputs[step_id]['expected_outputs'][k][k2]
          
          if v.is_a? String and m = v.match(/\#\{(\w+)\}/)
            (1.. m.size-1).each do |i|
              h_var[m[i]] ||= []
	      h_var[m[i]].push [step_id, k, k2]
            end
          end
          
        end
      end
    end
  end

  puts h_var.to_json

end
