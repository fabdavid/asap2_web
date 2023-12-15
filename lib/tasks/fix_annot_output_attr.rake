desc '####################### Fix annot output_attr.name'
task fix_annot_output_attr: :environment do
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

  h_std_methods = {}
  StdMethod.where(:obsolete => false).all.each do |std_method|
    h_std_methods[std_method.id] = std_method
    h_res = Basic.get_std_method_attrs(std_method, h_steps[std_method.step_id])
    h_std_method_attrs[std_method.id] = h_res[:h_attrs]
#    h_std_method_attrs[std_method.id].each_key do |k|
    #      puts "DATASET: " + h_std_method_attrs[std_method.id][k]['dataset'].to_json
#    end
  end

  Step.all.each do |step|
    h_outputs[step.id] = Basic.safe_parse_json(step.output_json, {})    
  end

#  h_outputs.each_key do |k| 
#    puts "k: #{k}"
#    if h_outputs[k]['expected_outputs']
# #   puts h_outputs[k]['expected_outputs'].keys.map{|k2| k2.to_s + ":" + h_outputs[k]['expected_outputs'][k2]['dataset'].to_json}.join("\n")
#    end	 
#  end

  h_not_found = {}
  
  Project.order("id desc").all.each do |p|

   
    
    annots = p.annots
    annots.where(:output_attr_id => nil).each do |a|
   
      run = a.run

      h_var = {
        "step_tag" => h_steps[a.step_id].tag,
        "run_num" => run.num,
        "std_method_name" => (s = h_std_methods[run.std_method_id]) ? s.name : '',
	"nber_dims" => a.nber_rows
      }
#      puts h_var.to_json
      #      run = a.run
      #  h_tmp_attrs = h_std_method_attrs[run.std_method_id]
      h_tmp_outputs = h_outputs[a.step_id]['expected_outputs'] 
      found = 0
      output_attr_name = ''
      h_tmp_outputs.each_key do |attr_name|
        dataset_name_ori = h_tmp_outputs[attr_name]['dataset']
	dataset_name = dataset_name_ori.dup
        #dataset_name.gsub('', '')
        if dataset_name 
          h_var.each_key do |v|
            if h_var[v]
              dataset_name.gsub!(/\#\{#{v}\}/, h_var[v].to_s)
#              puts dataset_name
            end	       
          end
          dataset_name.gsub!(/\-/, "_")
          annot_name = a.name.gsub(/\-/, "_")
          t1 = dataset_name.split("_").sort
          t2 = annot_name.split("_").sort - [h_var['step_tag']]
          if dataset_name.match(/wilcox/) and a.name.match(/wilcox/) and dataset_name != annot_name
            #puts a.to_json
            puts dataset_name_ori + ": " + dataset_name + " <=> " + annot_name
            #            exit
          end
          if dataset_name == annot_name
            output_attr_name = attr_name
            found = 1
          end
        end
      end
      
      if found == 1
        #puts output_attr_name
        output_attr = OutputAttr.where(:name => output_attr_name).first
        if output_attr        
          h_upd = {
            :output_attr_id => output_attr.id
          }
          
          a.update_attributes(h_upd)
        end
      else
        h_not_found[a.name] = 1
        puts "Not found #{a.name}!!!"
      end
    end
  end

  puts h_not_found.keys.join(",")
  
end
