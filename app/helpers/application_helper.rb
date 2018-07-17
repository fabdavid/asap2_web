module ApplicationHelper

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
