module ApplicationHelper

  def display_archive_status archive_status
    html = ''
    if archive_status
      html= "<i class='" + archive_status.icon_class + "' title='" + archive_status.name.capitalize  + "'></i>"
    end
    return html
  end

  def display_run_attrs run, h_attrs, h_std_method_attrs
    
    html = '<p>' +
      h_attrs.keys.reject{|attr| reject_attrs = @h_dashboard_card[run.step_id]["reject_attrs"] and reject_attrs.include? attr}.map{|attr|
      v = h_attrs[attr]
      txt = ''
      list_datasets = []
      if (v.is_a? Hash and v['run_id'])
        list_datasets.push(v)
      elsif (v.is_a? Array and v[0]['run_id'])
        list_datasets = v
      else
         std_method_attr = (h_std_method_attrs[run.std_method_id]) ? h_std_method_attrs[run.std_method_id][attr] : nil
        if std_method_attr
          txt = "<span class='badge badge-light cursor-help' data-toggle='tooltip' data-placement='bottom' title='" + [std_method_attr['label'], std_method_attr['description']].select{|e| e and !e.empty?}.join(": ") + "'>#{attr}:" +  v.to_s + "</span>"
        else
          txt = ''
        end
      end
      list_datasets.each_index do |dataset_i|
        v = list_datasets[dataset_i]
        tmp_txt = ''
        tmp_run = Run.where(:id => v['run_id']).first
        tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
        if tmp_run and tmp_step
          additional_classes = ''
          additional_classes = 'input_lineage pointer' if action_name == 'get_step'
          txt = "<span id='input_lineage_#{tmp_run.id}' class='badge badge-dark #{additional_classes}'>#{attr}:#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "") + "</span>"
        else
          txt = "<span class='badge badge-seconday input_lineage pointer'>#{attr}:NA</span>"
        end
      end
      #     txt = "<span id='input_lineage_#{tmp_run.id}' class='badge badge-secondary input_lineage pointer'>#{attr}:#{tmp_step.name}" + tmp_txt                                                                     
      
      txt}.join(" ") + "</p>"
    return html
  end
  
  def display_run_attrs_txt  run, h_attrs, h_std_method_attrs
    list = []
     h_attrs.keys.reject{|attr| reject_attrs = @h_dashboard_card[run.step_id]["reject_attrs"] and reject_attrs.include? attr}.map{|attr|
      v = h_attrs[attr]
      txt = ''
      list_datasets = []
      if (v.is_a? Hash and v['run_id'])
        list_datasets.push(v)
      elsif (v.is_a? Array and v[0]['run_id'])
        list_datasets = v
      else
        std_method_attr = (h_std_method_attrs[run.std_method_id]) ? h_std_method_attrs[run.std_method_id][attr] : nil
        if std_method_attr
          txt = "#{attr}:" +  v.to_s
        else
          txt = ''
        end
      end
      list_datasets.each_index do |dataset_i|
        v = list_datasets[dataset_i]
        tmp_txt = ''
        tmp_run = Run.where(:id => v['run_id']).first
        tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
        if tmp_run and tmp_step
          additional_classes = ''
          additional_classes = 'input_lineage pointer' if action_name == 'get_step'
          txt = "#{attr}:#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "")
        else
          txt = "#{attr}:NA"
        end
      end
      list.push txt
    }
    return list.join(" ")
  end
  
  def display_download_btn run, h_file
    h_output = h_file[:h_output]
    title = ""
    if h_file[:datasets].size > 0
      title = "data-toggle='tooltip' data-placement='bottom' title='Added/changed datasets: " + h_file[:datasets].map{|d| d[:name] + ((d[:dataset_size]) ? " [#{display_mem(d[:dataset_size])}]" : '')}.join(", ") + "'" 
      #+ ((h_output['dataset_size']) ? " [#{display_mem(h_output['dataset_size'])}]" : '') 
      
    end
    return "<div id='run_#{run.id}_#{h_output["onum"]}' class='btn btn-sm btn-outline-secondary download_file_btn' #{title}><div class='float-right'><sub>#{display_mem(h_output["size"])}</sub></div><div class='download_btn_text'>#{h_output["filename"]}</div></div>"
  end

  def get_run_attrs run
    
   if run and step = @h_steps[run.step_id]
      h_attrs = JSON.parse(run.attrs_json)
      attr_txt = h_attrs.keys.reject{|attr|  @h_dashboard_card[step.id] and reject_attrs = @h_dashboard_card[step.id]["reject_attrs"] and reject_attrs.include? attr}.map{|attr|
        v = h_attrs[attr]
        txt = ''
        if (v.is_a? Hash and v['run_id'])
          tmp_txt = ''
          tmp_run = Run.where(:id => v['run_id']).first
          tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
          if tmp_run and tmp_step
            #          txt = "#{attr}:#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "")                                                                 
          else
            txt = "#{attr}:NA"
          end
          #     txt = "<span id='input_lineage_#{tmp_run.id}' class='badge badge-secondary input_lineage pointer'>#{attr}:#{tmp_step.name}" + tmp_txt                                                                                                                                                                                                    
        else
          txt = "#{attr}:" +  v.to_s
        end
        txt }.join(" ")
      return attr_txt
    else
      return "NA"
    end

  end

  def display_run run
    if run and step = @h_steps[run.step_id]
      std_method_name = (std_method = run.std_method) ? std_method.name : "Unknown"
      h_attrs = JSON.parse(run.attrs_json)
      attr_txt = h_attrs.keys.reject{|attr|  @h_dashboard_card[step.id] and reject_attrs = @h_dashboard_card[step.id]["reject_attrs"] and reject_attrs.include? attr}.map{|attr|
        v = h_attrs[attr]
        txt = ''
        if (v.is_a? Hash and v['run_id'])
          tmp_txt = ''
          tmp_run = Run.where(:id => v['run_id']).first
          tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
          if tmp_run and tmp_step
            #          txt = "#{attr}:#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "")
          else
            txt = "#{attr}:NA"
          end
          #     txt = "<span id='input_lineage_#{tmp_run.id}' class='badge badge-secondary input_lineage pointer'>#{attr}:#{tmp_step.name}" + tmp_txt                                                                            
        else
          txt = "#{attr}:" +  v.to_s
        end
        txt }.join(" ")
      return "#{step.label}" + ((step and step.multiple_runs == true) ? " ##{run.num} #{std_method_name} #{attr_txt}" : "")
    else
      return "NA"
    end
  end

  def display_run_short run
    if run and step = @h_steps[run.step_id]
      std_method_name = (std_method = run.std_method) ? std_method.name : nil
      return  "<span class='badge badge-secondary' title='#{get_run_attrs(run)}'>#{step.label}" + ((step and step.multiple_runs == true) ? " ##{run.num}" : "") + ((std_method_name) ? " #{std_method_name}" : "") + "</span>"
    else
      return "NA"
    end
  end

  def display_run_short_txt run
     if run and step = @h_steps[run.step_id]
      std_method_name = (std_method = run.std_method) ? std_method.name : nil
      return  "#{step.label}" + ((step and step.multiple_runs == true) ? " ##{run.num}" : "") + ((std_method_name) ? " #{std_method_name}" : "")
    else
      return "NA"
    end
  end

  def display_status status
    return "<span class='badge badge-#{status.label}'><i class='#{status.icon_class} #{status.name}-icon'></i> #{status.name}</span>"
  end
  
  def display_status_todo status, h_status_names
     return "<span class='badge badge-#{status.label}'><i class='#{status.icon_class} #{status.name}-icon'></i> #{h_status_names[status.id]}</span>"
  end

  def display_status_short status
    return "<i class='#{status.icon_class} #{status.name}-icon2'></i>"
  end


  def display_status_runs status, nber_runs
    return "<span class='badge badge-#{status.label}'>#{nber_runs} <i class='#{status.icon_class} #{status.name}-icon'></i></span>"
  end

  def display_mem b
    if b
      g = b.to_f/1000000000
      m = b.to_f/1000000
      k = b.to_f/1000    
      return (g < 1) ? ((m < 1) ? ((k < 1) ? "#{b.round(3-(b.to_i.to_s.size))}b" : "#{k.round(3-(k.to_i.to_s.size))}Kb") : "#{m.round(3-(m.to_i.to_s.size))}Mb") : "#{g.round(3-(g.to_i.to_s.size))}Gb"
    else
      return 'Unknown'
    end
  end

  def display_elapsed_time(t)
  
    secs = (Time.now - t).to_i    
    return duration(secs) + " ago" #secs.to_s + " seconds ago"  
  end

  def duration(secs)
    
    res = ''
    if secs != 0
      
      mins  = secs / 60
      hours = mins / 60
      days  = hours / 24
      final = []
      if days >= 1
        final.push("#{days.to_i}d")
      end
      if hours >= 1
        final.push("#{(hours % 24).to_i}h")
      end
      if mins >= 1 and days == 0
        final.push("#{(mins % 60).to_i}m")
      end
      if secs >= 0 and hours == 0
        final.push("#{(secs % 60).to_i}s")
      end
      res = final.join(" ")
    else
      res = "0s"
    end
    
    return res
  end

  def display_de_selections(de)
    selections = [[(sel = Selection.where(:id => de.selection1_id).first) ? sel.label : 'NA', de.nb_cells_sel1]]
    if de.selection2_id and sel = Selection.where(:id => de.selection2_id).first
      selections.push([sel.label, de.nb_cells_sel2]) 
    end
   # [de.selection1_id, de.selection2_id].compact.each do |sel_id|
   #   selections.push(Selection.where(:id => sel_id).first)
   # end
    return "on selection" + ((selections.size > 1) ? 's' : '') + " #{selections.map{|e| e[0] + " [" + e[1].to_s + "]"}.join(" - ")}"    
  end

  def display_method_label(label)
    label_method = ''
    p = []
    if m = label.match(/(.+?) \((.+?)\)/)
      label_method = m[1]
      p = m[2].split(", ")
    end
    return raw("<span class='label label-info'>#{label_method}</span> " + p.map{|e| t = e.split("="); 
  #               if t[0] == 'Custom geneset' or attr['name'] == 'global_geneset'
  #      tmp_val = GeneSet.find(tmp_val).label
  #    end

"<span class='label label-default'>#{t[0]}: #{t[1]}</span>"}.join(" "))
  end

  def display_method_label2(o, o_method)
    h_attrs = JSON.parse(o.attrs_json)
    list_attrs = JSON.parse(o_method.attrs_json)
    p = []
    list_attrs.reject{|attr| attr['widget'] == nil  or !h_attrs[attr['name']]}.each do |attr|
      tmp_val = h_attrs[attr['name']]
      p.push("<span class='label label-default'>#{attr['label']}: " + ((!tmp_val or tmp_val == '') ? (attr['null_name'] || '') : ((attr['type'] == 'bool') ? (( tmp_val == '1') ? 'Yes' : 'No' ) : tmp_val)) + "</span>")#attr['name'])
    end
    return raw("<span class='label label-info'>#{o_method.label}</span> " + p.join(" "))
  end

  def display_date(c)
    n = Time.now
    html = "" #<table class='display_date'><tr><td class='day'>"                                                                                                              
    if n.day == c.day and n.month == c.month and n.year == c.year
      html += "Today"
    elsif n.day == c.day + 1 and n.month == c.month and n.year == c.year
      html += "Yesterday"
    else
      html += "#{c.year}-#{"0" if c.month < 10}#{c.month}-#{"0" if c.day < 10}#{c.day}"
    end
    #   html += "</td><td>"                                                                                                                                                      
    html += "<br/>at #{"0" if c.hour < 10}#{c.hour}:#{"0" if c.min < 10}#{c.min}" #</td></tr></table>"                                                                            
  end

  def display_date_short(c)
    n = Time.now
    html = "" #<table class='display_date'><tr><td class='day'>"                                                                                                                                                      
    if n.day == c.day and n.month == c.month and n.year == c.year
      html += "Today"
    elsif n.day == c.day + 1 and n.month == c.month and n.year == c.year
      html += "Yesterday"
    else
      html += "#{c.year}-#{"0" if c.month < 10}#{c.month}-#{"0" if c.day < 10}#{c.day}"
    end
    #   html += "</td><td>"                                                                                                                                                                                           
    html += " #{"0" if c.hour < 10}#{c.hour}:#{"0" if c.min < 10}#{c.min}" #</td></tr></table>"                                                                                                                
  end

  
  def display_date2(c)
    n = Time.now
    html = "" #<table class='display_date'><tr><td class='day'>"                                                                                                                                       
    if n.day == c.day and n.month == c.month and n.year == c.year
      html += "Today"
    elsif n.day == c.day + 1 and n.month == c.month and n.year == c.year
      html += "Yesterday"
    else
      html += "#{c.year}-#{"0" if c.month < 10}#{c.month}-#{"0" if c.day < 10}#{c.day}"
    end
  end

  def display_warnings(warnings)
    html = ''
    if warnings and warnings.size > 0
      html += "<div class='alert alert-warning alert-sm'>"
      html += "<h4 class='alert-heading'>Warnings</h4>"
      warnings.each do |warning|
        html += "<p class='mb-0'>#{warning || ''}</p>"
      end 
      html += "</div>"
    end 
    return raw html
  end

  def display_errors(errors)
    html = ''
    if errors and errors.size > 0
      html += "<div class='alert alert-danger alert-sm'>"
      html += "<h4 class='alert-heading'>Warnings</h4>"
      errors.each do |error|
        html += "<p class='mb-0'>#{error || ''}</p>"
      end
      html += "</div>"
    end
    return raw html
  end

  def display_batch_file()
 
    res = @all_results[:parsing]['batch_file']

    html = '<tr><td><span data-toggle="tooltip" title="Provided batch file">Provided batch file</span></td><td>'
    if File.exist?( Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'group.txt') and res
      if File.exist?( Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'parsing' + 'group.tab') and res['nber_lines_parsed'] > 0
        html += link_to raw("<button class='btn btn-primary btn-xs'>Download batch file</button> "), get_file_project_path(@project.key, :step => 'parsing', :filename => 'group.tab') + " "
      else 
        html += "<span class='label label-danger'>Empty file</span> "
      end 
      html += "<span class='label #{(res['nber_lines_parsed'] > 0) ? 'label-info' : 'label-danger'}'>#{res['nber_lines_parsed']} cells found</span> "
      if res['nber_lines_unparsed'] > 0
       html += "<span class='label label-warning'>#{res['nber_lines_unparsed']} lines ignored (bad format or wrong cell name)</span> "
      end 
      html += "<span class='label #{(res['nber_lines_parsed'] > 0) ? 'label-info' : 'label-danger'}'>#{res['nber_groups']} groups detected</span> "
      html += "<span class='label label-warning'>Batch effect correction cannot be performed with only one group</span>" if res['nber_groups'] == 1
    else 
      html += "None "
    end 
    html += "<span>To add a batch file " + "<span id='edit_project_link' class='btn btn-default btn-xs' class='edit_project'>Edit project</span>" + "</span>" if editable? @project
    html += "</td></tr>"

    return raw html
    
  end

end
