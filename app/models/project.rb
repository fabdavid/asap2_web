class Project < ApplicationRecord

  before_save :broadcast_new_status, if: :will_save_change_to_status_id?

  belongs_to :user
  belongs_to :status
  belongs_to :step
  has_many :fus
  belongs_to :session, :optional => true
  has_many :clusters
  has_many :selections
  has_many :diff_exprs
  belongs_to :norm, :optional => true
  belongs_to :filter_method, :optional => true
  belongs_to :organism
  has_many :project_dim_reductions
  has_many :gene_enrichments
  has_many :project_steps
  has_many :courses
  has_many :jobs
  has_many :gene_sets
  has_many :shares

  def broadcast_new_status
    ProjectStatusBroadcastJob.perform_later self
  end

  NewParsing = Struct.new(:project) do
    def perform
      project.parse
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 1).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        project.update_attributes(:error => lines, :status_id => 4)
      end
    end
  end

  NewFilter = Struct.new(:project) do
    def perform
      project.start_filter
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 2).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        project.update_attributes(:error => lines, :status_id => 4)
      end
    end
  end

  NewNorm = Struct.new(:project) do
    def perform
      project.start_norm
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 3).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        project.update_attributes(:error => lines, :status_id => 4)
      end
    end
  end


  def parse_files 
    job = Basic.create_job(self, 1, self, :parsing_job_id, 1)
    #    p[:filename]='input'
     #     parse
    delayed_job = Delayed::Job.enqueue NewParsing.new(self), :queue => 'fast'
    job.update_attributes(:delayed_job_id => delayed_job.id) #job.id)
  end

  def parse_task
    cmd = "rails --trace parse[#{self.id}] 2>&1 log/parse.log"
    logger.debug("CMD = #{cmd}")
    `#{cmd}`
  end
  
  def run_filter
    #        filter
    fm = self.filter_method
    job = Basic.create_job(self, 2, self, :filtering_job_id, (fm) ? fm.speed_id : 'fast') if fm
    delayed_job = Delayed::Job.enqueue NewFilter.new(self), :queue => (fm and fm.speed) ? fm.speed.name : 'fast'
#    self.start_filter
    job.update_attributes(:delayed_job_id => delayed_job.id) if job
  end
  
  def run_norm
#    nm = Norm.where(:id => self.norm_id).first
#    job = Basic.create_job(self, 3, self, :normalization_job_id, nm.speed_id)
#    norm
    nm = Norm.where(:id => self.norm_id).first
    job = Basic.create_job(self, 3, self, :normalization_job_id, nm.speed_id) if nm
#    delayed_job = Delayed::Job.enqueue NewNorm.new(self), :queue => (nm and nm.speed) ? nm.speed.name : 'fast'
    self.start_norm
#    job.update_attributes(:delayed_job_id => delayed_job.id) if job
  end

  def get_cells
      
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
    cells = File.open(project_dir + 'parsing' + 'output.tab', 'r').gets.chomp.split("\t")
    genes_header = cells.shift
    return cells
    
  end

  def parse_batch_file
    
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + self.user.id.to_s + self.key
    
    h_cells = {}
    get_cells().each do |cell|
      h_cells[cell]=1
    end
    
    ## copy group file                                                                                                                                                         

    if File.exist?(tmp_dir + "group.txt")
      h_parsing = {:nber_lines_parsed => 0, :nber_lines_unparsed => 0, :nber_groups => 0}
      h_groups = {}
      #        FileUtils.cp tmp_dir + "group.txt", tmp_dir + "parsing" + "group.tab"                                                                                                                                                  
      File.open(tmp_dir + "group.txt", 'r') do |f|
        File.open(tmp_dir + "parsing" + "group.tab", 'w') do |f2|
          while(l = f.gets) do
            tab = l.chomp.split("\t")
            puts tab.to_json
            if tab.size == 2  and h_cells[tab[0]]
              h_parsing[:nber_lines_parsed]+=1
              h_groups[tab[1]]=1
              f2.write(l)
            else
              h_parsing[:nber_lines_unparsed]+=1
            end
          end
        end
      end
      h_parsing[:nber_groups] = h_groups.keys.size

      ### delete file if empty
      
      if h_parsing[:nber_lines_parsed] == 0
        File.delete(tmp_dir + "parsing" + "group.tab")
      end

      ### get existing output.json

      h = JSON.parse(File.read(tmp_dir + "parsing" + "output.json"))
      h['batch_file'] = h_parsing 

      ### rewrite output.json
      
      File.open(tmp_dir + "parsing" + "output.json", 'w') do |f|
        f.write(h.to_json)
      end
    end
  end


  
  def write_download_file step
    project = self
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user.id.to_s + project.key
    
    ### get gene_file                                                                                                                                                                                        
    puts "read gene names"             
    if File.exists?(tmp_dir + "parsing" + 'gene_names.json')
      list_gene_names = JSON.parse(File.read(tmp_dir + "parsing" + 'gene_names.json'))
    end
    ### get file                                                                                                                                                                                                               
    filename = "output.tab"
    data = ""
    tmp_data = []
    if File.exist?(tmp_dir + step + filename)

      File.open(tmp_dir + step + filename, 'r') do |f|
        if list_gene_names
          #          tmp_data.push(f.gets) ## get header                                                        
          File.open(tmp_dir + step + ('dl_' + filename), 'w') do |f2|
            f2.write(f.gets)
            #i = 0
            while l = f.gets do
              t = l.split("\t")
              i = t.shift.to_i
              e = [[0,1,2].map{|j| list_gene_names[i][j]}.select{|e| e and e!=''}.join("|")]
              # tmp_data.push((e + t).join("\t"))
              f2.write (e + t).join("\t")      
              # i+=1
            end
          end
          #            f2.write tmp_data.join("")
        else
          #           data = f.readlines.join("")
          FileUtils.cp tmp_dir + step + filename, tmp_dir + step + ('dl_' + filename) 
        end
        
        #        File.open(tmp_dir + step + ('dl_' + filename), 'w') do |f|
        #        f.write(data)
        #      end
      end
    end
  end
  
  def create_gene_file tmp_dir, data, p, organism_id

    list_gene_names = []
    not_found_genes = []
    duplicated_genes = []
    
    if p['gene_name_col'] != 'NA'
    
      ### get data to speed up                          
      #logger.debug("ORGANISM: " + self.organism_id)
      genes = Gene.where(:organism_id => organism_id).all
      h_genes = {}
      h_gene_id_by_identifier={}
      genes.map{|g|
        h_genes[g.id]=g
        h_gene_id_by_identifier[g.ensembl_id.downcase]||=[]
        h_gene_id_by_identifier[g.ensembl_id.downcase].push(g.id)
        h_gene_id_by_identifier[g.name.downcase]||=[]
        h_gene_id_by_identifier[g.name.downcase].push(g.id)
      }
      
      i=0
      data.each do |row|
        gn = row[p[:gene_name_col].to_i]
          gn.gsub!(/['"]/, '')
        #logger.debug("PARAMS: " + p[:gene_name_col].to_s + " - " + row.to_json )
        if !h_gene_id_by_identifier[gn.downcase]
          not_found_genes.push([i, gn])
          list_gene_names.push([gn, "", ""])
        else
          ensembl_ids = h_gene_id_by_identifier[gn.downcase].map{|g_id| h_genes[g_id].ensembl_id}
          gene_names = h_gene_id_by_identifier[gn.downcase].map{|g_id| h_genes[g_id].name}.sort
          list_gene_names.push([gn, ensembl_ids.join(","), gene_names.join(",")])
        end
        i+=1
      end
    else
      i=0
      data.each do |row|
        gn = "Unknown gene #{i+1}"
        not_found_genes.push([i, gn])
        list_gene_names.push([gn, "", "", gn])
        i+=1
      end
    end

    ### edit gene_names if duplicates + warnings                                                                    
    if p['gene_name_col'] != 'NA'
      h_count_gene_names = {}
      data.each_index do |i|
        gn_text = list_gene_names[i].join("|")
        tmp_gn = (list_gene_names[i][1] != '') ? list_gene_names[i][1] : list_gene_names[i][0]
        #        tmp_gn = list_gene_names[i].join("|")
        h_count_gene_names[gn_text]||=0
        h_count_gene_names[gn_text]+=1
        tmp_count = h_count_gene_names[gn_text]
        duplicated_genes.push([gn_text, 1]) if tmp_count == 2
        list_gene_names[i][0] += ",#{tmp_count}" if tmp_count > 1
      end
      #h_warnings_data[:duplicated_genes].uniq!

      duplicated_genes.each_index do |i|
        gn = duplicated_genes[i][0]
        c = h_count_gene_names[gn]
        duplicated_genes[i][1]= c
      end
    end
    
    ### write file
    File.open(tmp_dir + 'gene_names.json', 'w') do |f|
      # list_gene_names.each_index do |i|
      #   e = list_gene_names[i]
      f.write(list_gene_names.to_json)
      # end
    end
    
    return [list_gene_names, not_found_genes, duplicated_genes] 
  end

  def update_not_found_genes current_step_dir, previous_step_dir
    # File.new(not_found_genes_file, 'w') do |f2|    
    # read result                                                                                                                                                                                                               
    h_num = {}
    File.open(current_step_dir + "output.tab" , 'r') do |f|
      header = f.gets
      while(l = f.gets)
        t = l.chomp.split("\t")
        h_num[t[0]]=1
      end
    end

    #    f2.write(h)
    ### compute how many not found genes in parsing are still present in filtering results and generate a new list file                                                                                                         
    filtered_list = []
    not_found_genes_file = previous_step_dir + "not_found_genes.txt"
    File.open(not_found_genes_file, 'r') do |f|
      while(l = f.gets)
        l.chomp!
        t = l.split("\t")
        filtered_list.push(l) if h_num[t[0]]
      end
    end
    
    #write file                                                                                                                                                                                                                 
    new_not_found_genes_file = current_step_dir + "not_found_genes.txt"
    File.open(new_not_found_genes_file, 'w') do |f|
      f.write(filtered_list.join("\n") + "\n")
    end
    
    #update json file                                                                                                                                                                                                           
    filename = current_step_dir + "output.json"
    results_json = File.open(filename, 'r').read
    results = JSON.parse(results_json)
   # results['warnings']||={}
    results['nber_not_found_genes']=filtered_list.size
      
    File.open(filename, 'w') do |f|
      f.write(results.to_json)
    end
    
  end
  
  def parse
    
    p = JSON.parse(self.parsing_attrs_json) if self.parsing_attrs_json
    
    start_time = Time.now
    self.update_attributes(:status_id => 2)
    project_step = ProjectStep.where(:project_id => self.id, :step_id => 1).first
    project_step.update_attributes(:status_id => 2)
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
    tmp_dir = project_dir + 'parsing'
    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

    filepath = File.readlink(project_dir + ("input." + self.extension)) 
    logger.debug("CMD_ls4 " + `ls -alt #{filepath}`)

    #    Options:
    #-col %s                 Name Column [none, first, last].
    #-o %s           Output folder
    #-f %s   File to parse.
    #-organism %i    Id of the organism.
    #-header %b      The file has a header [true, false].
    #-d %s   Delimiter.
    #-skip %i                Number of lines to skip at the beginning of the file.
    
    #cmd = "#{APP_CONFIG[:docker_call]} \"java -jar /srv/ASAP.jar -T Parsing -organism #{self.organism_id} -o #{tmp_dir} -f #{project_dir + ("input." + self.extension)} -col #{p['gene_name_col']} -d '#{p['delimiter']}' -header #{(p['has_header']) ? 'true' : 'false'} -skip #{p['skip_line']}\""

#    cmd = "#{APP_CONFIG[:docker_call]} \"java -jar /srv/ASAP.jar -T Parsing -organism #{self.organism_id} -o #{tmp_dir} -f #{project_dir + ("input." + self.extension)} -col #{p['gene_name_col']} -d '#{p['delimiter']}' -header #{(p['has_header']) ? 'true' : 'false'}\""  
    options = []
    options.push("-sel '#{p['sel_name']}'") if p['sel_name']
    options.push("-col #{p['gene_name_col']}") if p['gene_name_col']
    options.push("-d '#{p['delimiter']}'") if p['delimiter'] and p['delimiter'] != ''
    options.push("-header " + ((p['has_header'] and p['has_header'] == '1') ? 'true' : 'false')) if p['has_header']
    options.push("-ncells #{p['nb_cells']}")
    options.push("-ngenes #{p['nb_genes']}")
    options.push("-type #{p['file_type']}")
    options_txt = options.join(" ")

    cmd = "#{APP_CONFIG[:docker_call]} \"java -jar /srv/ASAP.jar -T Parsing -organism #{self.organism_id} -o #{tmp_dir} -f #{filepath} #{options_txt}\""
    logger.debug("#{cmd}")

    queue = 1

    logger.debug("CMD_ls4 " + `ls -alt #{filepath}`)
    output_file = tmp_dir + "output.loom"
    output_json = tmp_dir + "output.json"
    #    FileUtils.touch output_json if !File.exist?(output_json)
    job = Basic.run_job(logger, cmd, self, self, 1, output_file, output_json, queue, self.parsing_job_id, self.user)
    
    #    cmd = "rails parse_batch_file[#{self.key}]"
    #    logger.debug("CMD: " + cmd)
    #    `#{cmd}`
    
    content_json_file = File.read(output_json)
    status_id = 3
    h_parsing={}
    begin
      h_parsing = JSON.parse(content_json_file)
      Basic.finish_step(logger, start_time, self, 1, self, output_file, output_json)
    rescue Exception => e
      status_id = 4
      h_parsing['displayed_error']='Bad format for the input file.'
      File.open(output_json, 'w') do |f|
        f.write(h_parsing.to_json)
      end
    end
    status_id = 4 if h_parsing['displayed_error'] or h_parsing['original_error']
    ### update duration                                                                                                                                                            
    #  Basic.finish_step(logger, start_time, self, 1, self, output_file, output_json)
    # h_parsing = JSON.parse(File.read(tmp_dir + 'output.json'))
    self.update_attributes(
                           :duration => Time.now - start_time,
                           :status_id => status_id,
                           :nber_cells => h_parsing['nber_cells'] || nil,
                           :nber_genes => h_parsing['nber_genes'] || nil
                           )
    project_step.update_attributes(:status_id => status_id)   
  end
  
  def parse2
    
    begin

      puts "Start parsing..."
      require "csv"
    
      p = JSON.parse(self.parsing_attrs_json) if self.parsing_attrs_json
      
      start_time = Time.now
      self.update_attributes(:status_id => 2)
      project_step = ProjectStep.where(:project_id => self.id, :step_id => 1).first
      project_step.update_attributes(:status_id => 2)

      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
      tmp_dir = project_dir + 'parsing'
      Dir.mkdir(tmp_dir) if !File.exists?(tmp_dir)

      #cmd = "java -jar #{Rails.root}/lib/parsing.jar -organism #{self.organism_id} -o "

      tmp_data = CSV.read(project_dir + "input.txt", { :col_sep => p['delimiter'], :encoding => 'iso-8859-1:utf-8'})
      
      ## remove empty cells
      tmp_data.each_index do |i|
        tmp_data[i].compact!
        tmp_data[i].reject!{|e| e.match(/^\s*$/)}#.compact!
      end

      h_warnings_data = {
        :not_found_genes => [], 
        :not_int_values => [], 
        :duplicated_genes => [],
        :duplicated_standards => []
      }

      h_stats={
        :nber_zeros => 0,
        :nber_ercc => 0,
        :is_count_table => 1,
        :is_numeric_table => 1,
        :nber_all_duplicated_genes => 0
      }

      h_warnings = {}
      
      ### skip lines
      
      tmp_data.shift(p['skip_line'].to_i)
      
      ### extract header
      
      header = nil    
      header = tmp_data.shift if p['has_header']
      #      header.reject!{|e| e == ''}

      ### find standard nber of cols
      
      median_nber_cols = tmp_data.map{|row| row.size}.median
      
      ### create header if doesn't exist
      
      header ||= ['Genes'] + (1 .. (median_nber_cols-((p['gene_name_col'] != 'NA') ? 1 : 0))).to_a.map{|i| "Cell_#{i}"} 

      ### initialize standards table
      
      standards = []

      ### delete first item header
      if header.size == median_nber_cols and p['has_header']
        if p['gene_name_col'] == 1
          header.shift 
        elsif p['gene_name_col'] == -1 
          header.pop
        end
      end
      
      ### add Genes at the beginning of header if necessary
      header.unshift('Genes') if header.size == median_nber_cols -1 or (p['gene_name_col'] == 'NA' and p['has_header'])

      ### check nber columns and get a dataset without the lines having a wrong number of lines
      ### + write the discarded lines
      h_warnings[:bad_nber_col_header]=1 if header.size != median_nber_cols      
      data = []
      h_standards={}
      File.open(tmp_dir + 'discarded_lines.txt', 'w') do |f|
        tmp_data.each do |row|
          if row.size != median_nber_cols
            h_warnings[:variable_nber_cols]=1
            f.write(row.join("\t") + "\n")
          elsif p[:gene_name_col] != 'NA' and gn = row[p['gene_name_col'].to_i] and gn.match(/^ERCC-/)
            standards.push([gn] + row.reject{|e| e == gn})
            h_standards[gn]||=0
            h_standards[gn]+=1
            h_warnings_data[:duplicated_standards].push([gn]) if h_standards[gn]==2
          else
            data.push(row)
          end
        end
      end
      
      ### check gene_names                                                                                      
      puts "check gene names..."                                
      list_gene_names, h_warnings_data[:not_found_genes], h_warnings_data[:duplicated_genes] = create_gene_file(tmp_dir, data, p, self.organism_id) #[]
      
      ### compute number of lines of genes duplicated (:nber_duplicated_genes corresponds to the number of uniq genes that are duplicated (or more))
      h_stats[:nber_all_duplicated_genes] = h_warnings_data[:duplicated_genes].map{|e| e[1]}.sum.to_i
      
      ### delete old gene name col and put back the gene names                         
      data.each_index do |i|
        # row = data[i]
        if p['gene_name_col'] == '0'
          data[i].shift
        elsif p['gene_name_col'] == '-1'
          data[i].pop
        end
        #  row.unshift((p['gene_name_col'] != 'NA') ? list_gene_names[i]  : "Gene_#{i}")
        data[i].unshift(i)
      end
      
      ### check if count table                                                                                                                                
      puts "check count table..." 
      list_sd=[]
      data.each_index do |row_i|
        row = data[row_i]
        (1 .. row.size-1).each do |cell_i|
          cell = row[cell_i]
          if cell != cell.to_i.to_s #!cell.match(/^[0-9]*$/)
            data[row_i][cell_i].gsub!(",", ".")            
            if !cell.match(/^[\d.]+([eE][\-+]?\d+)?$/) #or !cell.match(/^[\d.](e-?\d+)?+$/)
              h_stats[:is_numeric_table]=0
              raise "Found a non-numeric value at line #{row_i+1} / column #{cell_i+1} (header and gene column are not counted)"
              #   break
            else
              h_stats[:is_count_table]=0              
            end
            h_warnings_data[:not_int_values].push([row_i, cell_i, cell])
          #  break
          end
        end
        break if h_stats[:is_count_table]==0 and h_stats[:is_numeric_table]==0
      end

      puts "count zeros..."
      ### count zeros
      checked_value = 0
      checked_value = 0.0 if h_stats[:is_count_table] == 0 
      
      data.each do |row|
        (1 .. row.size-1).each do |cell_i|
          cell = row[cell_i]
          cell = cell.to_i
          h_stats[:nber_zeros]+=1 if cell == checked_value 
        end
      end
      
      ### create standards file
      puts "create standards file..."
      h_stats[:nber_ercc]=standards.size
      if standards.size > 0
        File.open(tmp_dir + ("ercc.tab"), 'w') do |f|
          standards.unshift(header)
          f.write(standards.map{|row| row.join("\t")}.join("\n") + "\n")
        end
      else
        File.delete(tmp_dir + ("ercc.tab")) if  File.exist?(tmp_dir + ("ercc.tab"))
      end

      ### put the header back                                                                                                   
      data.unshift(header)

      ### write checked data     
      puts "write checked data..."
      File.open(tmp_dir + ("output.tab"), 'w') do |f|
        data.each do |row|
          f.write(row.join("\t") + "\n")
        end
      end
      
      ### final warnings stats                                                                                                                                                                                     
      h_warnings_data.each_key do |k|
        h_warnings[('nber_' + k.to_s).intern] = h_warnings_data[k].size
      end
    
      ### write metadata      
      puts "write metadata..."
      h_parsing =  {:nber_genes => data.size-1, :nber_cells => data.first.size-1}
      File.open(tmp_dir + 'output.json', 'w') do |f|
        #   h_parsing =  {:nber_genes => data.size-1, :nber_cells => data.first.size-1} 
        h_warnings.keys.map{|k| h_parsing[k]=h_warnings[k]}
        h_stats.keys.map{|k| h_parsing[k]=h_stats[k]}
        f.write(h_parsing.to_json)
      end
      
      ### write warning files     
      puts "write warnings..."
      h_warnings_data.each_key do |k|
        File.open(tmp_dir + (k.to_s + '.txt'), 'w') do |f|
          f.write("Genes\t#occurences\n") if k == :duplicated_genes
          h_warnings_data[k].each do |row|
            f.write(row.join("\t") + "\n")
          end
        end
      end

      ## write result files to download
      puts "write download file"
      write_download_file('parsing')

      ## copy group file 
      if File.exist?(project_dir + "group.txt")
        FileUtils.cp project_dir + "group.txt", tmp_dir + "group.tab"
      end

      ### update duration
      self.update_attributes(
                             :duration => Time.now - start_time, 
                             :status_id => 3, 
                             :nber_cells => h_parsing[:nber_cells], 
                             :nber_genes => h_parsing[:nber_genes])      
      project_step.update_attributes(:status_id => 3)
      #      Delayed::Worker.logger.debug("End work")
      
    rescue Exception => e
      puts "write error"
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
      tmp_dir = project_dir + 'parsing'
      File.open(tmp_dir + 'output.json', 'w') do |f|
        h_errors = {:displayed_error => e.message}
        f.write(h_errors.to_json)
      end
      self.update_attributes(:duration => Time.now - start_time, :error_message => e.message + "----" + e.backtrace.join("\n"),  :status_id => 4)
      project_step.update_attributes(:status_id => 4, :error_message => e.message + "----" + e.backtrace.join("\n"))
      
    end
   #    f.close
  end

  def start_filter

    require 'basic'
    logger.debug("BLA!!!!!")
    start_time = Time.now
    self.update_attributes(:status_id => 2)
    project_step = ProjectStep.where(:project_id => self.id, :step_id => 2).first
    project_step.update_attributes(:status_id => 2)

    require "csv"
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
    output_dir = project_dir + 'filtering'
    
    FileUtils.rm_r output_dir if File.exist?(output_dir)
    
    if self.filter_method_id
      
      Dir.mkdir(output_dir) if !File.exists?(output_dir)


      filter_method = FilterMethod.find(self.filter_method_id)
      list_p = []
      h_parameters = JSON.parse(self.filter_method_attrs_json)
      list_attrs = JSON.parse(filter_method.attrs_json)
      
      list_attrs.reject{|e| e['not_in_cmd_line']}.each do |attr|
        list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
      end

      ercc_file = nil
      ercc_filename = project_dir + 'parsing' + "ercc.tab"
      ercc_file = ercc_filename if h_parameters['ercc_file_exists']

      #    logger.debug("H_PARAMETERS: " + h_parameters.to_json)
      #    logger.debug("LIST_ATTRS: " + list_attrs.to_json)
      log_file = project_dir + 'filtering' + "output.log"
      err_file = project_dir + 'filtering' + "output.err"
      cmd = ["#{APP_CONFIG[:docker_call]}" + " '" + "Rscript --vanilla /srv/filtering.R",  project_dir + 'parsing' + 'output.tab', project_dir + 'filtering', filter_method.name, list_p.join(' '), ercc_file, "1> #{log_file} 2> #{err_file}", "'"].compact.join(" ") 
       logger.debug "CMD: #{cmd.to_json}"
#      ### search potentially running script
#      job = Job.where(:project_id => self.id, :step_id => 2, :status_id => 2).first
#      if job and `ps -ef | grep 'rvmuser' | grep '#{job.pid}' | wc -l`.to_i > 0
#        Process::kill 0, job.pid
#        job.update_attributes(:status_id => 6)
#      end
      
      queue = filter_method.speed_id || 1

      output_file = output_dir + 'output.tab'
      output_json = output_dir + 'output.json'
      job = Basic.run_job(logger, cmd, self, self, 2, output_file, output_json, queue, self.filtering_job_id, self.user)
      
      if File.exists?(output_file)
        update_not_found_genes(output_dir, project_dir + "parsing")
      end
      #    ## write result files to download 
      #    write_download_file('filtering')
      gene_names_file = project_dir + 'parsing' + 'gene_names.json'
      cmd = "#{APP_CONFIG[:docker_call]} -c 'java -jar /srv/ASAP.jar -T CreateDLFile -f #{output_file} -j #{gene_names_file} -o #{output_dir + 'dl_output.tab'}'"
      logger.debug("CMD: " + cmd)
      `#{cmd}`
    else
      
      File.symlink project_dir + 'parsing', output_dir
        
      end
      
      ## write result files to download                                                                                                                                                                                        
      #    write_download_file('filtering')
      
      ### update duration                                                                                                     
      if self.filter_method_id
        Basic.finish_step(logger, start_time, self, 2, self, output_file, output_json) 
      else
        project_step.update_attributes(:status_id => 3)
        self.update_attributes(:duration => Time.now - start_time, :status_id => 3) 
      end
      
    
#    duration = Time.now - start_time
#    if File.exists?(output_file)
#      self.update_attributes(:duration => Time.now - start_time, :status_id => 3)
#      project_step.update_attributes(:status_id => 3)
#      job && job.update_attributes(:status_id => 3)
#    else
#      self.update_attributes(:duration => Time.now - start_time, :status_id => 4)
#      project_step.update_attributes(:status_id => 4)
#      job && job.update_attributes(:status_id => 4)
#    end
    #      Delayed::Worker.logger.debug("End work")                            
#    end
  end

  def start_norm

    require 'basic'
    
    start_time = Time.now
    self.update_attributes({:status_id => 2})
    project_step = ProjectStep.where(:project_id => self.id, :step_id => 3).first
    project_step.update_attributes(:status_id => 2)
    
    #logger.debug("Parsing")                                                                                                  
    require "csv"
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
    output_dir = project_dir + 'normalization'
    
    FileUtils.rm_r output_dir if File.exist?(output_dir)
    
    if self.norm_id
      
      Dir.mkdir(output_dir) if !File.exist?(output_dir)
      
      
      norm = Norm.find(self.norm_id)
      list_p = []
      h_parameters = JSON.parse(self.norm_attrs_json)
      list_attrs = JSON.parse(norm.attrs_json)
      
      list_attrs.reject{|e| e['not_in_cmd_line']}.each do |attr|
        list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
      end
      
      group_file = 'null'
      group_filename = project_dir + 'parsing' + "group.tab"
      group_file = group_filename if h_parameters['batch_file_exists']  #File.exist?(group_filename) and h_parameters[attr['name']]
      
      ercc_file = nil
      ercc_filename = project_dir + 'parsing' + "ercc.tab"
      ercc_file = ercc_filename if h_parameters['ercc_file_exists']
      
      cmd = "#{APP_CONFIG[:docker_call]} 'Rscript --vanilla /srv/normalization.R " + [(project_dir + 'filtering' + 'output.tab'), (project_dir + 'normalization'), norm.name, group_file, list_p.join(' '), ercc_file].compact.join(" ") + " 2>&1 > #{project_dir + 'normalization' + "output.log"}'"
      logger.debug("CMD: " + cmd)
      #   Basic::launch_cmd(self, cmd)
      #      pid = spawn(cmd)
      #      Process.waitpid(pid)
      
      queue = norm.speed_id || 1
      
      output_file = output_dir + 'output.tab'
      output_json = output_dir + 'output.json'
      job = Basic.run_job(logger, cmd, self, self, 3, output_file, output_json, queue, self.normalization_job_id, self.user)
      
      #      if stopped == false
      
      if File.exists?(output_file)
        update_not_found_genes(output_dir, project_dir + "filtering")
      end
      ## write result files to download  
      #write_download_file('normalization')
      gene_names_file = project_dir + 'parsing' + 'gene_names.json'
      cmd = "#{APP_CONFIG[:docker_call]} -c 'java -jar /srv/ASAP.jar -T CreateDLFile -f #{output_file} -j #{gene_names_file} -o #{output_dir + 'dl_output.tab'}'"
      logger.debug("CMD: " + cmd)
      `#{cmd}`
      
    else
      
      if File.symlink? project_dir + 'filtering'
        File.symlink project_dir + 'parsing', output_dir
      else
        File.symlink project_dir + 'filtering', output_dir
      end
    end
    
    ## write result files to download                       
    #    if File.exists?(output_file)                                               
    #    write_download_file('normalization')
    #    end
    ### update duration                           
    
    if self.norm_id
      Basic.finish_step(logger, start_time, self, 3, self, output_file, output_json)
    else
      self.update_attributes(:duration => duration, :status_id => 3)                                                                        
      project_step.update_attributes(:status_id => 3)   
    end
    
    if File.exist?(output_dir + 'output.tab')
      ### start dim_reductions        
      init_dim_reductions 
    end
    #    duration = Time.now - start_time
    #    if File.exists?(output_file)
    #      self.update_attributes(:duration => duration, :status_id => 3)
    #      project_step.update_attributes(:status_id => 3)
    #       ### start dim_reductions
    #      init_dim_reductions
    #    else
    #      self.update_attributes(:duration => duration, :status_id => 4)
    #      project_step.update_attributes(:status_id => 4)
    #    end
    #    end
  end
  
  
  def init_dim_reductions
    
    self.update_attributes(:step_id => 4, :status_id => 2)
    project_step = ProjectStep.where(:project_id => self.id, :step_id => 4).first
    project_step.update_attributes(:status_id => 2)
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + self.user_id.to_s + self.key
    output_dir = project_dir + 'visualization'
    
    FileUtils.rm_r output_dir if File.exist?(output_dir)
    
    Dir.mkdir(output_dir) if !File.exists?(output_dir)

    #    self.project_dim_reductions.map{|e| e.update_attributes(:status_id => 1, :duration => 0)}

    DimReduction.all.each do |dr|
      h_attrs = {}
      if dr.id < 5
        JSON.parse(dr.attrs_json).each do |e|
          h_attrs[e['name']] = e['default'].to_s
        end
      elsif [5, 6].include?(dr.id) 
        h_attrs = {:dataset => 'normalization'}
      end
      #      if h_attrs.keys.size == 0
      
      if dr.name == 'tsne'
        norm_results = JSON.parse(File.read(project_dir + 'normalization' + 'output.json'))
        max_val = ((norm_results['nber_cells'].to_f-1)/3).to_d.truncate(3).to_f
        # logger.debug("PERPLEXITY: " + max_val.to_s + "---" + h_attrs['perplexity'].to_s + "..." + norm_results['nber_cells'].to_s)
        h_attrs['perplexity'] = max_val.to_s if h_attrs['perplexity'].to_f > max_val
        # logger.debug("PERPLEXITY: " + h_attrs.to_json)
      end
      
      h = {
        :dim_reduction_id => dr.id,
        :attrs_json => h_attrs.to_json,
        :user_id => self.user.id, #(current_user) ? current_user.id : 1,
        :status_id => nil, #(dr.id < 5) ? 1 : nil,
        :duration => 0
      }
      
      visualization_dir = output_dir + dr.name
      Dir.mkdir(visualization_dir) if !File.exist?(visualization_dir)
      
      new_pdr = ProjectDimReduction.where(:dim_reduction_id => dr.id, :project_id => self.id).first
      if !new_pdr
        new_pdr = ProjectDimReduction.new(h)
        self.project_dim_reductions << new_pdr
        # else
        #   new_pdr.update_attributes(:status_id => 1, :duration => 0)
      else
        new_pdr.update_attributes(h)
      end
      if dr.id < 3
        #        Basic.create_job(new_pdr, 4, self, :job_id, dr.speed_id)
        #        new_pdr.delay.run
        job = Basic.create_job(new_pdr, 4, self, :job_id, dr.speed_id)
        #  pdr.delay(:queue => (dr.speed) ? dr.speed.name : 'fast').run                                                                                                                                                     
        delayed_job = Delayed::Job.enqueue ProjectDimReduction::NewVisualization.new(new_pdr), :queue => (dr.speed) ? dr.speed.name : 'fast'
#        new_pdr.run(nil)
        job.update_attributes(:delayed_job_id => delayed_job.id) 

      end
      #      new_pdr.run
      #     end
    end
  end
  
end
