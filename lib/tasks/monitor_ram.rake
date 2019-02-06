desc '####################### Monitor RAM'
task monitor_ram: :environment do
  puts 'Executing...'
  
  now = Time.now
  
  require 'sys/proctable'
#  require 'get_process_mem'
  
  p = Sys::ProcTable.ps.last.to_json
#  mem = GetProcessMem.new(p.pid)
#  puts mem.inspect	 

  while (1) do 
    
    Run.where(:status_id => 2).all.each do |run| ## get all runs being executed
      
      list_children_processes = Sys::ProcTable.ps.select{ |pe| pe.ppid == run.pid } ##.select{ |pe| pe.ppid == 3396 }
      
      #  puts list_children_processes.map{|p| "#{p.pid}, #{p.ppid}"}.to_json
      
      end	
      
      sleep(1)
      
  end

end
