module ApplicationHelper

  def project_label p
    return p.name
  end

  def identifier_link id, id_type
    return link_to (id_type.name.to_s + ":" + id.to_s), id_type.url_mask.gsub(/\#\{.+?\}/, id)
 #   return 'bla'
  end

  def prepare_metadata_grouped_list annots
    h = {} 
    annots.select{|a| a.step_id and @h_steps[a.step_id]}.map{|a| k = (a.imported and @h_steps[a.step_id].label == 'Imported metadata') ? 0 : ((a.imported and  @h_steps[a.step_id].label != 'Imported metadata') ? 1000 : a.step_id); h[k] ||=[]; h[k].push([a.name.gsub(/\/.{3}_attrs\//, ''), a.id])}
    h.each_key do |k|
      h[k].sort!
    end
    l = []; h.keys.map{|k| l.push([k, h[k]])} 
    l.sort!{|a, b| ((@h_steps[a[0]]) ? @h_steps[a[0]].rank : a[0]) <=> ((@h_steps[b[0]]) ? @h_steps[b[0]].rank : b[0])} 
    h_extra_step = {0 => 'Manually imported metadata', 1000 => 'Imported metadata'} 
    l.map!{|e| [((![0, 1000].include?(e[0]) and  @h_steps[e[0]]) ? @h_steps[e[0]].label : h_extra_step[e[0]]), e[1]]} 
    l.unshift(["-------------", [["Select a metadata", '']]]) 
    return l
  end
  
  def srp_link srp_code
    return link_to srp_code, "https://www.ncbi.nlm.nih.gov/sra?term=#{srp_code}"
  end

  def display_cla cla, h_cots, h_genes
    ontology_terms = (cla.cell_ontology_term_ids) ? cla.cell_ontology_term_ids.split(",").map{|cot_id|  h_cots[cot_id.to_i].name}.join(" ") : nil
    html = '<p>'
#    html += cla.id.to_s
    html += raw(cla.name) + " " if cla.name and cla.name != ontology_terms
#    html += h_cots.to_json
    html +=  cla.cell_ontology_term_ids.split(",").map{|cot_id| [h_cots[cot_id.to_i].name, cot_id]}.sort.map{|t| "<span class='badge badge-info'>" + t[0] + "</span>"}.sort.join(" ") if cla.cell_ontology_term_ids
    html += "<br/>"
    html += "<div class='cla_list_genes'>" + cla.up_gene_ids.split(",").map{|gene_id| [(h_genes[gene_id.to_i].name || h_genes[gene_id.to_i].ensembl_id), gene_id]}.sort.map{|t| "<span class='badge badge-success ensembl_gene pointer' data-gene_id=" + t[1] + ">" + t[0] + "</span>"}.sort.join(" ") + "</div>" if cla.up_gene_ids
    html += "<br/>"
    html += "<div class='cla_list_genes'>" + cla.down_gene_ids.split(",").map{|gene_id| [(h_genes[gene_id.to_i].name || h_genes[gene_id.to_i].ensembl_id), gene_id]}.sort.map{|t| "<span class='badge badge-danger ensembl_gene pointer'>" + t[0] + "</span>"}.sort.join(" ") + "</div>" if cla.down_gene_ids 
    html += "</p>"

    return html
  end

  def display_cla_full cla, h_cots, h_genes
    html = '<p>'
    html += "<b>" + raw(cla.name) + "</b><br/>" if cla.name
    html += "Cell ontology terms: " + cla.cell_ontology_term_ids.split(",").map{|cot_id| [h_cots[cot_id.to_i].name, cot_id]}.sort.map{|t| "<span class='badge badge-info'>" + t[0] + "</span>"}.sort.join(" ") if cla.cell_ontology_term_ids
    html += "<br/>"
    html += "Up-regulated (Marker) genes: " + cla.up_gene_ids.split(",").map{|gene_id| [(h_genes[gene_id.to_i].name || h_genes[gene_id.to_i].ensembl_id), gene_id]}.sort.map{|t| "<span class='badge badge-success ensembl_gene pointer'  data-gene_id=" + t[1] + ">" + t[0] + "</span>"}.sort.join(" ") if cla.up_gene_ids
    html += "<br/>"
    html += "Down-regulated genes: " + cla.down_gene_ids.split(",").map{|gene_id| [(h_genes[gene_id.to_i].name || h_genes[gene_id.to_i].ensembl_id), gene_id]}.sort.map{|t| "<span class='badge badge-danger ensembl_gene pointer'  data-gene_id=" + t[1] + ">" + t[0] + "</span>"}.join(" ") if cla.down_gene_ids 

     html += "<small><i>#{cla.comment}</i></small>"

    html += "</p>"
    return html
  end

  def display_annot annot    
    col_name = ([1, 3].include? annot.dim) ? 'cell' : 'column'
    row_name = ([2, 3].include? annot.dim) ? 'gene' : 'row'
    col_name = col_name.pluralize if annot.nber_cols and annot.nber_cols > 1
    row_name = row_name.pluralize if annot.nber_rows and annot.nber_rows > 1
    return "<button id='annot_#{annot.id}_btn' class='btn btn-outline-secondary btn-sm annot_btn'>#{annot.name} <span class='badge badge-light'>#{annot.nber_cols} #{col_name}</span> <span class='badge badge-light'>#{annot.nber_rows} #{row_name}</span></button>"
    
  end

  def display_reference a
    return a.authors.split(";")[0] + ", #{a.year}"
  end

  def display_archive_status archive_status
    html = ''
    if archive_status
      html= "<i class='" + archive_status.icon_class + "' title='" + archive_status.name.capitalize  + "'></i>"
    end
    return html
  end

  def display_run_attrs_base run, h_attrs, h_std_method_attrs, opt
    
    input_lineage_class = (opt[:input_lineage_class]) ? opt[:input_lineage_class] : 'input_lineage'

    array_dataset = []
    
    array = 
      h_attrs.keys.reject{|attr| (reject_attrs = @h_dashboard_card[run.step_id]["reject_attrs"] and reject_attrs.include? attr) or
      (opt[:reject_if_default] and (std_method_attr = (e = h_std_method_attrs[run.std_method_id]) ? e[attr] : nil) and
       attr_default = (std_method_attr['default']) ? std_method_attr['default'].to_s : '' and attr_default == h_attrs[attr].to_s 
       )
     }.map{|attr|
      v = h_attrs[attr]
      txt = ''
      list_datasets_by_attr_name = {}
      if (v.is_a? Hash and v['run_id'])
        list_datasets_by_attr_name[attr]||=[]
        list_datasets_by_attr_name[attr].push(v)
      elsif (v.is_a? Array and v[0].is_a? Hash and v[0]['run_id'])
        list_datasets_by_attr_name[attr] = v
      else
         std_method_attr = (h_std_method_attrs[run.std_method_id]) ? h_std_method_attrs[run.std_method_id][attr] : nil
        if std_method_attr
          txt = "<span class='badge badge-light cursor-help wrap' data-toggle='tooltip' data-placement='bottom' title=\"" +  [std_method_attr['label'], (std_method_attr['description_text'] || std_method_attr['description'] || 'No description'), ((std_method_attr['default']) ? std_method_attr['default'].to_s : 'NODEFAULT'), opt[:reject_if_default].to_s
                            ].select{|e| e and !e.empty?}.join(": ") + "\">#{attr}:" +  v.to_s + "</span>"
        else
          txt = ''
        end
      end
      
      ### get annots
      h_annots = {}
      Annot.where(:id => list_datasets_by_attr_name.keys.map{|attr| list_datasets_by_attr_name[attr].map{|e| e['annot_id']}}.flatten.uniq.compact).all.map{|a| h_annots[a.id] = a}

      list_datasets_by_attr_name.each_key do |attr_name|
        if list_datasets_by_attr_name[attr_name].size < 10
          
          list_datasets_by_attr_name[attr_name].each_index do |dataset_i|
            v = list_datasets_by_attr_name[attr_name][dataset_i]
            if v['annot_id'] and  h_annots[v['annot_id']]
              v['output_dataset'] = h_annots[v['annot_id']].name
            end
            tmp_txt = ''
            tmp_run = Run.where(:id => v['run_id']).first
            tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
            if tmp_run and tmp_step
              additional_classes = ''
              additional_classes = (input_lineage_class + ' pointer') if ['get_step', 'get_run', 'get_de_gene_list', 'form_select_input_data'].include? action_name
              displayed_val = ''
              if v['output_dataset'] and m = v['output_dataset'].match(/^\/.{3}_attrs\/(.+)/)
                displayed_val = m[1]
              else
                displayed_val = "#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "")
              end
              array_dataset.push "<span id='input_lineage_#{tmp_run.id}' class='badge badge-dark #{additional_classes}'>#{attr}:#{displayed_val}</span>"
            else
              array_dataset.push "<span class='badge badge-seconday input_lineage pointer'>#{attr}:NA</span>"
            end
            
          end
        else
          array_dataset.push "<span class='badge badge-seconday input_lineage pointer'>#{attr}:#{list_datasets_by_attr_name[attr_name].size} datasets</span>" 
        end
      end
        #     txt = "<span id='input_lineage_#{tmp_run.id}' class='badge badge-secondary input_lineage pointer'>#{attr}:#{tmp_step.name}" + tmp_txt                                                                     
      
      txt}

    #    html = '<p>' + array_dataset.join(" ") + " " + array.join(" ") + "</p>"
    return {:datasets => array_dataset, :attrs => array} #html
  end

  def display_run_attrs run, h_attrs, h_std_method_attrs, opt
    h = display_run_attrs_base run, h_attrs, h_std_method_attrs, opt
    return  html = '<p>' + h[:datasets].join(" ") + " " + h[:attrs].join(" ") + "</p>"
  end
  def display_run_attrs2 run, h_attrs, h_std_method_attrs, opt
    h = display_run_attrs_base run, h_attrs, h_std_method_attrs, opt
    return  html =  h[:datasets].join(" ") + " " + h[:attrs].join(" ")
  end

  
  def display_run_attrs_txt  run, h_attrs, h_std_method_attrs
    list = []
     h_attrs.keys.reject{|attr| reject_attrs = @h_dashboard_card[run.step_id]["reject_attrs"] and reject_attrs.include? attr}.map{|attr|
      v = h_attrs[attr]
      txt = ''
      list_datasets = []
      if (v.is_a? Hash and v['run_id'])
        list_datasets.push(v)
      elsif (v.is_a? Array and v[0].is_a? Hash and v[0]['run_id'])
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

  def display_attrs_txt step_id, h_attrs, opt #, h_std_method_attrs, opt #, h_std_method_attrs
    list = []
    h_attrs.keys.reject{|attr| (reject_attrs = @h_dashboard_card[step_id]["reject_attrs"] and reject_attrs.include? attr)
    }.map{|attr|
      v = h_attrs[attr]
      txt = ''
      list_datasets = []
      if (v.is_a? Hash and v['run_id'])
        list_datasets.push(v)
      elsif (v.is_a? Array and v[0].is_a? Hash and v[0]['run_id'])
        list_datasets = v
      else
       # std_method_attr = (h_std_method_attrs[std_method.id]) ? h_std_method_attrs[run.std_method_id][attr] : nil
      #  if std_method_attr
          txt = "#{attr}:" + v.to_s
      #  else
      #    txt = ''
      #  end
      end
      list_datasets.each_index do |dataset_i|
        v = list_datasets[dataset_i]
        tmp_txt = ''
#        tmp_run = Run.where(:id => v['run_id']).first
#        tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
#        if tmp_run and tmp_step
#          additional_classes = ''
#          additional_classes = 'input_lineage pointer' if action_name == 'get_step'
#          txt = "#{attr}:#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "")
#        else
#          txt = "#{attr}:NA"
#        end
        if opt[:h_annots] and v['annot_id'] and annot = opt[:h_annots][v['annot_id']]
          tmp_run = opt[:h_runs][v['run_id'].to_i]
          tmp_step = (tmp_run) ? @h_steps[tmp_run.step_id] : nil
          if tmp_step
            txt = "#{attr}:#{tmp_step.name}" + ((tmp_step.multiple_runs == true) ? " #" + tmp_run.num.to_s : "") + " #{annot.name}"
          else
             txt = "#{attr}:#{annot.name}"
          end
        else
           txt = "#{attr}:#{v['annot_id']}:#{opt[:h_annots].keys.to_json}"
        end
      end
      list.push txt
    }
    return list.join(" ")
  end
  
  def display_download_btn run, h_file
    h_output = h_file[:h_output]
    title = ""
    h_filename = {
      'output.loom' => 'Loom file',
      'output.json' => 'JSON file'
    }
    if h_file[:datasets].size > 0
      title = "data-toggle='tooltip' data-placement='bottom' title='Added/changed datasets: " + h_file[:datasets].map{|d| d[:name] + ((d[:dataset_size]) ? " [#{display_mem(d[:dataset_size])}]" : '')}.join(", ") + "'" 
      #+ ((h_output['dataset_size']) ? " [#{display_mem(h_output['dataset_size'])}]" : '') 
      
    end
    return (h_output["size"] > 0) ? ("<div class='nowrap'><div id='run_#{run.id}_#{h_output["onum"]}' class='btn btn-sm btn-outline-secondary white-bg download_file_btn' #{title}><div class='float-right'><sub>#{display_mem(h_output["size"])}</sub></div><div class='download_btn_text'>#{h_filename[h_output["filename"]] || h_output["filename"]}</div></div>" + ((h_output["filename"]=='output.loom') ? " <span class='link_to_loom_tuto info-btn pointer'><sup><i class='fas fa-info-circle fa-lg'></i></sup></span>" : '') + "</div>") : ""
  end

  def display_specific_download_btn run, output_link, h_links
    output_key = output_link['key']
    h_link = h_links[output_key]
    h_output = (h_link) ? h_link[:h_output] : {}
    return  "<div id='run_#{run.id}_#{h_output["onum"]}-#{output_link['method']}' class='btn btn-sm btn-outline-secondary white-bg download_#{output_link['method']}_btn'>" + output_link['label'] + "</div>"# + h_files.to_json
  end

  def display_specific_output_download_btn run, h_steps
 
    h_buttons = {
      'ge' => "<div id='run_#{run.id}_ge_tsv_from_json' class='btn btn-sm btn-outline-secondary white-bg download_tsv_from_json_btn'>results.tsv</div>"
    }

    html = h_buttons[h_steps[run.step_id].name] || ''
    return html
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

  def display_run2 run, step, std_method
    return "<span id='show_run_#{run.id}' class='show_link show_run_link pointer'><b>##{run.num}</b> #{(step.multiple_runs == false) ? step.label : ((std_method) ? ((!params[:step_id]) ? (step.label + " ") : "") + ((std_method.name != 'parsing') ? std_method.label : '') : 'NA')}</span>"
  end

  def display_run_short run
    if run and step = @h_steps[run.step_id]
      std_method_name = (std_method = run.std_method) ? std_method.name : nil
      return  "<span class='badge badge-secondary' title='#{get_run_attrs(run)}'>#{step.label}" + ((step and step.multiple_runs == true) ? " ##{run.num}" : "") + ((std_method_name) ? " #{std_method_name}" : "") + "</span>"
    else
      return "NA#{run.to_json}#{step.to_json}"
    end
  end

  def display_run_short_txt run
     if run and step = @h_steps[run.step_id]
      std_method_name = (std_method = run.std_method) ? std_method.name : nil
      return  "#{step.label}" + ((step and step.multiple_runs == true) ? " ##{run.num}" : "") + ((std_method_name and std_method_name.downcase != step.label.downcase) ? " #{std_method_name}" : "")
    else
      return "NA"
    end
  end

   def display_run_ultra_short_txt run
     if run and step = @h_steps[run.step_id]
      std_method_name = (std_method = run.std_method) ? std_method.name : nil
      return  ((step and step.multiple_runs == true) ? "run#{run.num}" : "") + ((std_method_name) ? "_#{std_method_name}" : "")
    else
      return "NA"
    end
  end

  def display_status status
    return "<span class='badge badge-#{status.label}' title='#{status.name}'><i class='#{status.icon_class} #{status.name}-icon'></i> #{status.name}</span>"
  end
  
  def display_status_todo status, h_status_names
     return "<span class='badge badge-#{status.label}'><i class='#{status.icon_class} #{status.name}-icon'></i> #{h_status_names[status.id]}</span>"
  end

  def display_status_short status
    return "<i class='#{status.icon_class} #{status.name}-icon2'></i>"
  end

  def display_sum_status_short h_statuses, h_all_runs, run_ids
    h_counts = {}
    run_ids.each do |rid|
      h_counts[h_all_runs[rid].status_id]||=0
      h_counts[h_all_runs[rid].status_id]+=1
    end
    return h_counts.keys.sort{|a, b| h_statuses[a].rank <=> h_statuses[b].rank}.map{|status_id| display_status_runs(@h_statuses[status_id],  h_counts[status_id])}.join(" ")
  end

  def display_status_runs status, nber_runs
    return "<span class='badge badge-#{status.label}' title='#{status.name}'>#{nber_runs} <i class='#{status.icon_class} #{status.name}-icon'></i></span>"
  end

  def display_mem b
    if b
      g = b.to_f/1000000000
      m = b.to_f/1000000
      k = b.to_f/1000    
      return (g < 1) ? ((m < 1) ? ((k < 1) ? "#{b.round(3-(b.to_i.to_s.size))}b" : "#{k.round(3-(k.to_i.to_s.size))}Kb") : "#{m.round(3-(m.to_i.to_s.size))}Mb") : "#{g.round(3-(g.to_i.to_s.size))}Gb"
    else
      return ''
    end
  end

  def display_elapsed_time(t)
  
    secs = (Time.now - t).to_i    
    return duration(secs) + " ago" #secs.to_s + " seconds ago"  
  end

  def duration(secs)
    
    res = ''
    if secs and secs != 0
      
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

  def duration2(secs)
    res = ''
    if secs and secs != 0
      
      s = secs % 60
      mins  = secs / 60
      m = mins % 60
      hours = mins / 60
      h = hours % 24
      days  = hours / 24
      
      final = []
      if days.to_i > 0
        final.push("#{days.to_i}d")
      end
      if h > 0
        final.push("#{h.to_i}h")
      end
      if m > 0
        final.push("#{m.to_i}m")
      end
      if s > 0 #and hours == 0
        final.push("#{s.to_i}s")
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

  def display_output_dataset(run, output_filename, output_dataset)
    return raw(display_run_short(run) + "<span class='badge badge-light'>#{output_filename}:#{output_dataset}</span>")
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

  def display_file_format f
    return " <i class='far fa-file fa-3x'><div style='position:relative;top:-26px;left:6px;width:38px;font-size:10px;font-weight:bold;text-align:center;font-family:Arial, Helvetica, sans-serif;background-color:" +  ((f and f.color) ? f.color : 'grey') + ";color:white;padding:3px;border:2px solid white'>" + ((f and f.label) ? f.label : 'no label') + "</div></i>"
  end

end
