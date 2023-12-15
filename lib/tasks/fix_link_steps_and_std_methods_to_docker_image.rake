desc '####################### Fix link steps and std_methods to docker image instead of versions'
task fix_link_steps_and_std_methods_to_docker_image: :environment do
  puts 'Executing...'

  now = Time.now
  
  def upd_step e, step_id, attr_name
 # puts step_id
 #   puts " ->STEP: " + step_id.to_s + "->" + @h_steps[step_id].to_s + " USING " + attr_name.to_s	
    if @h_steps[step_id]
#      puts "MATCHING"
      e.update_attribute(attr_name, @h_steps[step_id])
    else
     puts " ->STEP: " + step_id.to_s + "->" + @h_steps[step_id].to_s + " USING " + attr_name.to_s
#      puts e.to_json
#      	       puts step_id
#	       puts attr_name
      
    puts "NOT MATCHING!"
    end
  end
  
  def upd_std_method e, std_method_id, attr_name
#    puts " ->STD_METHOD: " + std_method_id.to_s + "->" + @h_std_methods[std_method_id].to_s + " USING " + attr_name.to_s
    if @h_std_methods[std_method_id]
       e.update_attribute(attr_name, @h_std_methods[std_method_id])
 #     puts "MATCHING"
    else
 puts " ->STD_METHOD: " + std_method_id.to_s + "->" + @h_std_methods[std_method_id].to_s + " USING " + attr_name.to_s
  
    puts "NOT MATCHING!"
    end
  end

  #get step and std_method equivalences between version 6 and 5
  @h_steps = {}
  Step.where(:version_id => 6).all.each do |s|
    new_s = Step.where(:version_id => 5, :name => s.name).first
    @h_steps[s.id] = new_s.id
  end
  
  @h_std_methods = {}
  StdMethod.where(:version_id => 6).all.each do |s|
    new_s = StdMethod.where(:version_id => 5, :name => s.name).first
    @h_std_methods[s.id] = new_s.id
  end
  
  Project.where(:version_id => 6).all.each do |p|
    puts "##############{p.key}"
    
    ## changing runs
    p.runs.each do |r|
      upd_std_method(r, r.std_method_id, :std_method_id)
      upd_step(r, r.step_id, :step_id)
    end

    ## changing reqs
     p.reqs.each do |r|
      upd_std_method(r, r.std_method_id, :std_method_id)
      upd_step(r, r.step_id, :step_id)
    end
    
    ## changing del_runs
    p.del_runs.each do |r|
      upd_std_method(r, r.std_method_id, :std_method_id)
      upd_step(r, r.step_id, :step_id)
    end

    ## changing active_runs                                                                                                                                                                                            
    p.del_runs.each do |r|
      upd_std_method(r, r.std_method_id, :std_method_id)
      upd_step(r, r.step_id, :step_id)
    end

    ## changing annots
    p.annots.each do |r|
      upd_step(r, r.step_id, :step_id)
      upd_step(r, r.ori_step_id, :ori_step_id)
    end		      

    ## changing project_steps
    p.project_steps.each do |r|
      upd_step(r, r.step_id, :step_id)
    end

#    upd_step(p, p.step_id, :step_id)

  end

end
