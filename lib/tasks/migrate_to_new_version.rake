desc '####################### Migrate to new version'
task migrate_to_new_version: :environment do

  puts 'Executing...'

  now = Time.now


  ###add methods in StdMethod
  
  list_step_names = [:gene_filtering, :normalization, :visualization, :clustering, :de]
  list_old_method_controllers = [:filter_method, :norm, :dim_reduction, :cluster_method, :diff_expr_method]

  list_old_method_controllers.each_index do |i|

  oc =  list_old_method_controllers[i]
    om = oc.to_s.camelize.constantize
    step = Step.where(:name => list_step_names[i].to_s).first

    om.all.each do |e|

      
      h2 = {} #:handles_log => e.handles_log}
      [:handles_log, :creates_av_norm].each do |attr|
        cmd = "e.respond_to?(:#{attr})"
#	puts "CMD: " + cmd
#	puts eval("e.respond_to?(:handles_log)")       
        v = eval(cmd)
#        puts v
        if v
#	  puts "CMD: " + cmd
          h2[attr] = eval("e.#{attr}") 
        end
      end

#      puts h2.to_json

      h = {
        :step_id => step.id,
	:name => e.name,
        :label => e.label,   
        :short_label => (e.respond_to?(:short_label)) ? e.short_label : nil,
        :description => e.description,
        :program => e.program,
        :link => e.link,
        :speed_id => e.speed_id, #smallint references speeds,
        :attrs_json => e.attrs_json,
	:obj_attrs_json => h2.to_json, 
	#        :handles_log => e.handles_log,
        #        creates_av_norm bool default false,
        :created_at => e.created_at,
        :updated_at => e.updated_at
      }
   
      std_method = StdMethod.where({:step_id => step.id, :name => e.name}).first
      
      if ! std_method 
     
        std_method = StdMethod.new(h)
        std_method.save
      else
        std_method.update_attributes(:attrs_json => e.attrs_json, :obj_attrs_json => h2.to_json)
      end
    end		
  end
end
