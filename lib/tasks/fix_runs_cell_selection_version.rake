desc '####################### Fix runs'
task fix_runs_cell_selection_version: :environment do
  puts 'Executing...'

  now = Time.now

  old_step = Step.where(:version_id => 4, :name => 'cell_selection').first
  old_std_method = StdMethod.where(:version_id => 4, :name => 'cell_sel').first

  step = Step.where(:version_id => 5, :name => 'cell_selection').first
  std_method = StdMethod.where(:version_id => 5, :name => 'cell_sel').first

  Project.where(:version_id => 5).order("id desc").all.each do |p|
    
    runs = p.runs
    runs.select{|r| r.step_id == old_step.id and r.std_method_id == old_std_method.id}.each do |r|

        
      puts "Run #{r.id} has to be modified step: #{old_step.id} => #{step.id}; std_method #{old_std_method.id} => #{std_method.id}"
      r.update_columns({:step_id => step.id, :std_method_id => std_method.id})
    end
  end

end
