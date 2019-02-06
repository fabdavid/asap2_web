module StdStep

  class << self
    def create_instance obj_name, p

      @project = Project.where(:key => params[:project_key]).first
      
      if analyzable?(@project)

        step = Step.where(:obj_name => obj_name).first
        #        obj =  (obj.is_std_step == false and obj.method_obj_name) ? obj_name.camelize.constantize : StdRun
        obj = StdRun
        #        method_obj = (obj.is_std_step == false and obj.method_obj_name) ? obj.method_obj_name.camelize.constantize : StdMethod
        method_obj = StdMethod

        @o = obj.new(p) ##o for object
        @o.project_id = @project.id
        @o.user_id = (current_user) ? current_user.id : 1
        tmp_attrs = params[:attrs]
        @o.attrs_json = tmp_attrs.to_json

        @om =  method_obj.where(:id => @o.std_method_id).first  #om for object method
        if @om and @om.label #params[obj_name.to_sym][:std_method_id].match(/^\d+$/)
          dr_name = @om.label
        end
        #else
        #        step = Step.where(:obj_name => obj_name).first
        #  dr_name = step.name + " data"
        #end
        
#        fm = @gf.filter_method
        list_attrs = JSON.parse(@om.attrs_json)
        #    other_params = (["Input data=#{dr_name}"] + list_attrs.reject{|attr| attr['widget'] == nil}.map{|attr| "#{attr['label']}=" + ((attr['name'] == 'nbclust' and tmp_attrs['nbclust'] == '') ? 'Auto' : tmp_attrs[attr['name']].to_s)}).join(", ")                                                                                                                                                                                                                      
        other_params =  list_attrs.reject{|attr| attr['widget'] == nil or attr['name'] == 'nbclust'}.map{|attr| "#{attr['label']}=#{tmp_attrs[attr['name']].to_s}"}.join(", ")
        other_params = "(" + other_params + ")" if other_params != ''
        #[@diff_expr.diff_expr_method.label, other_params].join(" ")                                                                                                                                                                      
        #      @gf.label = [FilterMethod.where(:id => @gf.filter_method_id).first.label, ((tmp_attrs['nbclust'] != '') ? (tmp_attrs['nbclust'].to_s + " clusters") : '[Auto]') ,  ("on " + dr_name), other_params].join(" ")              
        @o.label = [obj.where(:id => @o.std_method_id).first.label, other_params].join(" ")
        @existing_o = obj.where(:project_id => @project.id, :label => @o.label, :step_id => @o.step_id, :std_run_id => @o.std_run_id).first
        last_o = obj.where(:project_id => @project.id, :step_id => @o.step_id).last
        @o.num = (last_o and last_o.num) ?  (last_o.num + 1) : 1
        #step = Step.where(:name => 'gene_filtering').first
        @project.update_attributes(:status_id => 1, :step_id => step.id) if @project.status_id > 2 and !@existing_o
#        respond_to do |format|
 
        if @existing_o
          @o = @existing_o
          @os= obj.where(:project_id => @project.id, :step_id => @o.step_id).all
          #          get_gf_data()                                                                                                                                                                                                      
          #          format.html {
          #            render :partial => 'index'
          #          }
        elsif @o.save
          job = Basic.create_job(@o, step.id, @project, :job_id, @om.speed_id)
          #       @cluster.update_attributes(:status_id => 1)#, :num => (last_cluster and last_cluster.num) ?  (last_cluster.num + 1) : 1)                                       
          session[:last_step_status_id]=2
          #         @cluster.delay(:queue => (cm.speed) ? cm.speed.name : 'default').run                                                                                                                                                
          delayed_job = Delayed::Job.enqueue obj::NewRun.new(@o), :queue => (@om.speed) ? @om.speed.name : 'default'
          job.update_attributes(:delayed_job_id => delayed_job.id) #job.id)                                                                                                                                                             
            #            @cluster.run                                                                                                                                                                                                     
#            @os=@project.gene_filterings
          @os= obj.where(:project_id => @project.id, :step_id => @o.step_id).all
          #          get_gf_data() ###                                                                                                                                                                                                  
        end
        
      end
      
    end
  end
end
