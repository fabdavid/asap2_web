desc '####################### Create correlation_plot'
task :create_correlation, [:pdr_id] => [:environment] do |t, args|
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
  
  input_filename = visualization_dir + 'input.tab'
  ori_input_file = project_dir + h_parameters['dataset'] + 'output.tab'
  
  cell_names = []
  File.open(ori_input_file, 'r') do |f|
    cell_names = f.gets.chomp.split("\t")
  end
  list_cols = [1]
  cell_names.shift
  cell_names.each_index do |i|
    cell_name = cell_names[i]
    if  h_parameters['cell_name_1'] == cell_name or h_parameters['cell_name_2'] == cell_name
      list_cols.push(i+2)
    end
  end

  cmd = "cut -f #{list_cols.join(',')} #{ori_input_file} > #{input_filename}"
puts cmd
  `#{cmd}`

  filename = project_dir + 'parsing' + "gene_names.json"
  gene_names = JSON.parse(File.read(filename)).flatten
#  h_genes = {}
#  gene_names.each do |identifier|
#    h_genes[identifier.downcase]=1
#  end  
 
  x = []
  y = []
  names = []
  
  File.open(input_filename, "r") do |f|
    header = f.gets
    while (l=f.gets) do
      t = l.chomp.split("\t")
      x.push(t[1])
      y.push(t[2])
      names.push(gene_names[t[0].to_i])
    end
  end
  
  h_res = {
    x: x,
    y: y,
    mode: 'markers',
    type: 'scatter',
    name: 'Genes',
    text: names,
    marker: { size: 12 }
  }
  
  File.open(output_json, 'w') do |f|
    f.write(h_res.to_json)
  end
  
  puts "Finished" 
end
