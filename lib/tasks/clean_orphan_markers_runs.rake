desc '####################### Clean_orphan_markers_runs'
task clean_orphan_markers_runs: :environment do
  puts 'Executing...'

  now = Time.now

  h_std_methods = {}
  StdMethod.all.map{|sm| h_std_methods[sm.id] = sm}
  
#  Project.where(:id => 17777).all.each do |p|
 Project.all.each do |p|
   
    all_runs = p.runs #| p.del_runs
    h_runs = {}
    all_runs.map{|e| h_runs[e.id] = e}    

    p.runs.select{|r| ["asap_markers", "asap_marker_enrichment"].include?(h_std_methods[r.std_method_id].name)}.each do |run|
      
      h_attrs = JSON.parse(run.attrs_json)
      h_attrs.each_key do |k|

        if m = h_attrs[k].to_s.match(/users\/(\d+)\/(\w+)\/\w+?\/(\d+)\/?/)
	linked_run = Run.where(:id => m[3].to_i).first
          if m[3] and !linked_run
            puts "Delete #{p.key} => #{run.id} using #{m[3]} #{!h_runs[m[3].to_i].to_json}"
	    RunsController.destroy_run_call(p, run)
          end
        end
      end
    end

  end
    
end
