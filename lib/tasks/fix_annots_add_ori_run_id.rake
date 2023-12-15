desc '####################### Fix annots => add ori_run_id'
task fix_annots_add_ori_run_id: :environment do
  puts 'Executing...'

  now = Time.now

  Project.order("id desc").all.each do |p|

    annots = p.annots.sort{|a, b| a.id <=> b.id}
    h_ori = {}
    annots.each do |a|
      #  t = a.name.split(/\//)
      if !h_ori[a.name] or a.name == '/matrix'
        h_ori[a.name]=[a.run_id, a.step_id]
      end
      #      puts "#{a.ori_run_id} set to #{h_ori[a.name]}"
      h_upd = {
        :ori_run_id => h_ori[a.name][0], 
        :ori_step_id => h_ori[a.name][1]
      }
      a.update_attributes(h_upd) #if !a.ori_run_id or !a.ori_step_id     
      
    end
  end
  
end
