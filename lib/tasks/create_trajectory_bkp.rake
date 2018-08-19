desc '####################### Create trajectory'
task :create_trajectory, [:pdr_id] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now

  puts args[:pdr_id]

  pdr = ProjectDimReduction.find(args[:pdr_id])
  h_parameters = JSON.parse(pdr.attrs_json)

  puts h_parameters.to_json

  project = pdr.project
  project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
  visualization_dir = project_dir + 'visualization' + pdr.dim_reduction.name

  output_json = visualization_dir + 'output.json'

  input_file = visualization_dir + 'input.tab'
  timeseries_file = project_dir + 'timeseries.txt'
  ori_input_file = project_dir + h_parameters['dataset'] + 'output.tab'
  
  h_output = {}
  h_cells = {}
  if h_parameters['selection_id'] and h_parameters['selection_id'] != ''
    selection = Selection.find(h_parameters['selection_id'])
    h_selection = {}
    selection_file = project_dir + 'selections' + "#{h_parameters['selection_id']}.txt"
    File.open(selection_file, "r") do |f|
      while(l = f.gets) do
        h_cells[l.chomp]=1
      end
    end
  end

  ### get gene names
  gene_names_file = project_dir + 'parsing' + "gene_names.json"
  list_names = JSON.parse(File.read(gene_names_file))

  #### get gene set
  h_genes = {}
  filename = ''
  if h_parameters['geneset_type'] == 'custom'
    filename = project_dir + 'gene_sets' + (h_parameters['custom_geneset'] + ".txt")
  elsif h_parameters['geneset_type'] == 'global' ### global gene set
    dir = Pathname.new(APP_CONFIG[:data_dir]) + "Genesets"
    gene_set = GeneSet.find(h_parameters['global_geneset'])
    filename = dir + gene_set.original_filename
  end

  if h_parameters['geneset_type'] != 'all'
    puts h_parameters['geneset_name']
    identifier = h_parameters['geneset_name'].gsub(/\s+[\:\[].+/, '')
    File.open(filename, 'r') do |f|
      while (l = f.gets) do
        t = l.chomp.split("\t")
        puts "-" + t[0] + "---" + identifier + "-"
        if t[0] == identifier #or h_parameters['geneset_type'] == 'all'
          # puts "toto"
          (3 .. (t.size-1)).to_a.each do |i|
            # puts i.to_s + "---" + t[i]
            h_genes[t[i].downcase] = 1
          end
        end
      end
    end
  end

  #puts h_genes.to_json
  File.open(input_file, "w") do |f|
    File.open(ori_input_file, "r") do |f2|
      header = f2.gets.chomp
      list_cells = header.split("\t")
      new_header = [list_cells[0]]
      (1 .. (list_cells.size-1)).to_a.each do |j|
        new_header.push(list_cells[j]) if h_cells[list_cells[j]] or h_parameters['selection_id'] == '' or !h_parameters['selection_id']
      end
      f.write new_header.join("\t") + "\n"
      while (l = f2.gets) do
        new_t = []
        t = l.chomp.split("\t")
        gene_names = [list_names[t[0].to_i][0].downcase, list_names[t[0].to_i][2].downcase]
        existing_gene_name = gene_names.map{|gn| h_genes[gn]}.compact.sum || 0
        if existing_gene_name > 0 or h_parameters['geneset_type'] == 'all'
          new_t = [list_names[t[0].to_i][0]]
          (1 .. (list_cells.size-1)).to_a.each do |j|
            if h_cells[list_cells[j]] or h_parameters['selection_id'] == '' or !h_parameters['selection_id']
              new_t.push(t[j])
            end
          end
          f.write new_t.join("\t") + "\n"
        else
          # puts "Gene not found: " + gene_names.join(", ")
        end
      end
    end
  end
  
  puts `wc -l #{input_file}`.to_i
  count_genes = `wc -l #{input_file}`.to_i - 1
  count_cells = `head -1 #{input_file} | wc -w`.to_i - 1
  puts 'count_genes'
  puts count_genes
  puts 'count_cells'
  puts count_cells
  if count_genes == 1
    h_output[:displayed_error]='Only one matching gene was found in your dataset'
  elsif count_genes == 0
    h_output[:displayed_error]='No matching gene was found in your dataset'
  #elsif count_genes * count_cells > 5000 * 500 # or count_genes > 5000 or count_cells > 500
  #  h_output[:displayed_error]='The heatmap is too large to be computed in reasonable time (>2.5M values). Please select less genes / cells.'
  end

  if h_output[:displayed_error]
    ### write output.json
    File.open(output_json, "w") do |f|
      f.write(h_output.to_json)
    end
  else
    puts h_parameters['timeseries']
    cmd = ["ulimit -s 16384 && /home/rvmuser/R-3.4.1/bin/Rscript --vanilla --max-ppsize=500000 lib/monocle.R", input_file, visualization_dir, h_parameters['reduction_method'], timeseries_file].join(" ")
    puts cmd
    `#{cmd}`
    puts "Finished"
  end
end
