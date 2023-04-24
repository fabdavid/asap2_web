class FusController < ApplicationController
  before_action :set_fu, only: [:show, :edit, :update, :destroy, :upload, :do_upload, :retrieve_data_from_url, 
                                :preparsing, :resume_upload, :update_status, :reset_upload]
  skip_before_action :verify_authenticity_token


  def retrieve_data_from_url

    
    #delayed_job = 
#    @fu.start_download
    params[:url].gsub!(/\s+/, "")
    Delayed::Job.enqueue Fu::NewDownload.new(@fu, params[:url]), :queue => 'fast'

#   @fu.download params[:url]
    #    require 'open-uri'
    
    #    filename = 'input_file'
    #    @valid_url = 0
    #    if !params[:url] =~ /\A#{URI::regexp(['http', 'https', 'ftp'])}\z/
    #      params[:url] = "http://" + params[:url]
    #    end
    #    if params[:url] =~ /\A#{URI::regexp(['http', 'https', 'ftp'])}\z/
    #      @valid_url = 1
#      if m = params[:url].match(/([^\/]+?\.)(tar|tgz|txt|loom|h5)/)
    #        filename = m[1] + m[2]
#      end
    #      ## update url and filename
    #      @fu.update_attributes({
    #                              :upload_file_name => filename, 
    #                              :url => params[:url]
    #                            })
    #      
    #      upload_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus' + @fu.id.to_s
    #      Dir.mkdir upload_dir if !File.exist? upload_dir 
    #      filepath = upload_dir + @fu.upload_file_name
    #      
    ##      IO.copy_stream(open(params[:url]), filepath)
    #      safe_download(params[:url], filepath)
    #      if File.exist? filepath
    #        @fu.update_attributes({:upload_file_size => File.size(filepath)})
    #      end
    #
    #    end
        render :partial => 'retrieve_data_from_url'
  end
  

  def preparsing

#    if params[:organism_id]

    @h_formats={}
    FileFormat.all.map{|f| @h_formats[f.name] = f}
    #      'RAW_TEXT' => {:color => 'green', :label => 'TXT', :description => 'raw text', :child_format => 'RAW_TEXT'}, 
    #      'LOOM' => {:color => 'red', :label => 'Loom', :description => 'LOOM', :child_format => 'LOOM'},
    #      'H5_10x' => {:color => 'orange', :label => '10x', :description => '10x (h5)', :child_format => 'H5_10x'},
    #      'ARCHIVE' => {:description => 'archive of raw text', :many => true, :child_format => 'RAW_TEXT'},
    #      'COMPRESSED' => {:description => 'compressed', :child_format => 'RAW_TEXT'},
    #      'ARCHIVE_COMPRESSED' => {:description => 'compressed archive of raw text', :many => true, :child_format => 'RAW_TEXT'}
    #    }
      
    @h_pred_vals = {
        '0' => '&epsilon;',
      '' => '?'
    }
      
    upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + @fu.id.to_s
    filepath = upload_dir + @fu.upload_file_name
    
    output_file = upload_dir + "output.json"
    dataset_file = upload_dir + "datasets.json"
    filelist_file = upload_dir + "file_list.json"
    upload_details_file = upload_dir + "upload.json"
    
    #    parsing_step = Step.where(:version_id => params[:version_id], :name => 'parsing').first
    version = Version.where(:id => params[:version_id]).first
    h_env = Basic.safe_parse_json(version.env_json, {})
    list_docker_image_names = h_env['docker_images'].keys.map{|k| h_env['docker_images'][k]["name"] + ":" + h_env['docker_images'][k]["tag"]}
    docker_images = DockerImage.where("full_name in (#{list_docker_image_names.map{|e| "'#{e}'"}.join(",")})").all
    asap_docker_image = docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
    parsing_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'parsing').first 

    ### get upload file                                                                                     
    @h_upload_details = {}
    if File.exist? upload_details_file
      @h_upload_details = JSON.parse(File.read(upload_details_file))
    end
    
    if !@h_upload_details['detected_format'] or ['ARCHIVE', 'ARCHIVE_COMPRESSED', 'COMPRESSED', 'RAW_TEXT'].include? @h_upload_details['detected_format']
        params[:gene_name_col]||= 'first'
      params[:delimiter]||=''
      #  params[:skip_line]||=0
      params[:has_header]||='1'
    end
    
    options = []    
    options.push("-sel '#{params[:sel]}'") if params[:sel]
    options.push("-col #{params[:gene_name_col]}") if params[:gene_name_col]
    options.push("-d '#{params[:delimiter]}'") if params[:delimiter] and params[:delimiter] != ''
    options.push("-header " + ((params[:has_header] and params[:has_header] == '1') ? 'true' : 'false')) if params[:has_header]
    options_txt = options.join(" ")
    
    ### get datasets
    @h_datasets = {}
    if File.exist? dataset_file
      @h_datasets = JSON.parse(File.read(dataset_file))
    end
    
    # get file list if it already exists                                                                                                                      
    @list_datasets = []
    if File.exist? filelist_file
      @list_datasets = JSON.parse(File.read(filelist_file))['list_files']
    end
    file_format = nil
    @error = nil
    @current_dataset = nil
    @log = ''
    if @h_datasets[options_txt]
      @current_dataset = @h_datasets[options_txt]
      @h_json = @current_dataset
      @error = @current_dataset['displayed_error'] if @current_dataset['displayed_error'] 
    else
      #      cmd = "#{APP_CONFIG[:docker_call]} \"java -jar /srv/ASAP.jar -T Preparsing #{options.join(" ")} -organism #{params['organism']} -f #{filepath} -o #{upload_dir}\""
      @cmd = ''
      if params['organism']
        begin
          new_filepath = Basic.convert_mtx_to_h5 filepath, logger
          if new_filepath != filepath
            file_format = 'MEX'
            filepath = new_filepath
#            @fu.update_attribute(:upload_file_name, File.basename(filepath))
          end
        rescue Exception => error
          logger.debug("ERROR:" + error.to_json)
        end
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T Preparsing #{options.join(" ")} -organism #{params['organism']} -f \"#{filepath}\" -o #{upload_dir} -h localhost:5434/asap2_development 2> #{upload_dir + 'output.err'}"
      else
        @h_metadata_types = {'1' => 'cell', '2' => 'gene'}
        project = @fu.project
        project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + project.user_id.to_s + project.key
        parsing_loom_file = project_dir + 'parsing' + 'output.loom'
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T PreparseMetadata #{options.join(" ")} -loom #{parsing_loom_file} -f \"#{filepath}\" -o #{upload_dir + 'output.json'} -which #{@h_metadata_types[params[:metadata_type]].upcase} 2> #{upload_dir + 'output.err'}"
      end
      logger.debug("FINAL_FORMAT:" + file_format.to_json)
      @log += output_file.to_s
      logger.debug "CMD #{@cmd}"
      @res = `#{@cmd}`
      @h_json = nil
      if File.exist? output_file
        output_json = File.read output_file
        output_json.gsub!(/\s+/, ' ')
        @log+= output_json
        
        if !output_json.empty?
          logger.debug output_json
          @h_json = JSON.parse(output_json)
          @h_json['detected_format'] = file_format || @h_json['detected_format']
          #{"detected_format":null,"list_groups":[{"group":"Pernille","nb_cells":6,"nb_genes":47729","is_count":1,"genes":["ENSMUSG00000000001","ENSMUSG00000000003","ENSMUSG00000000028","ENSMUSG00000000031","ENSMUSG00000000037","ENSMUSG00000000049","ENSMUSG00000000056","ENSMUSG00000000058","ENSMUSG00000000078","ENSMUSG00000000085"],"cells":["E5_S7","A1_S5","D6_S8","A9_S6","pos_control_S9","neg_control_S10"],"matrix":[[97.0,0.0,26.0,0.0,66.0,0.0],[0.0,0.0,0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0,13.0,0.0],[0.0,0.0,0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0,2.0,0.0],[0.0,0.0,0.0,8.0,12.0,0.0],[0.0,176.0,0.0,44.0,60.0,0.0],[1.0,33.0,0.0,0.0,4.0,0.0]]}]}
          
          ### record upload details if available                                                                                              
          if @h_json['detected_format'] and !params[:sel]
            @h_upload_details = {
              'detected_format' => file_format || @h_json['detected_format']              
            }
            
            File.open(upload_details_file, 'w') do |f|
              f.write @h_upload_details.to_json
            end
          end
          
          if @h_json['list_groups'] and @h_json['list_groups'].size == 1 and !@current_dataset ## it is a file and add new dataset
            
            current_dataset = @h_json['list_groups'].first
            
              ## predict parsing time 
            std_method = StdMethod.where(:step_id => parsing_step.id).first                                                                                                                                                
            @cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv fabdavid/asap_run:v#{params[:version_id]} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{params[:version_id]} #{std_method.id} #{current_dataset['nber_rows']} #{current_dataset['nber_cols']} 2>&1'"                                                                           
            pred_results_json = `#{@cmd}`.split("\n").first #.gsub(/^(\{.+?\})/, "\1")            
            h_pred_results = Basic.safe_parse_json(pred_results_json, {})
            
            #            h_pred_results = Basic.safe_parse_json(pred_results_json, {})              
            
            current_dataset['pred_max_ram'] = (h_pred_results['predicted_ram'] == 'NA') ? '' : h_pred_results['predicted_ram']
            current_dataset['pred_process_duration'] = (h_pred_results['predicted_time'] == 'NA') ? '' : h_pred_results['predicted_time']
            
            @h_json['list_groups'] = [current_dataset]
            ### re-write
            File.open(output_file, 'w') do |fw|
              fw.write @h_json.to_json
            end
            
            @current_dataset = current_dataset #@h_json['list_groups'].first
            @current_dataset['detected_format'] = @h_json['detected_format']
            
            ## read existing datasets.json          
            if File.exist? dataset_file
              @h_datasets = JSON.parse(File.read(dataset_file))            
            end
            #          h_datasets = {}
            #          @datasets.map{|d| h_datasets[d['group']]=1}
            if !@h_datasets[options_txt]
              @h_datasets[options_txt]= @current_dataset
              #          if !h_datasets[@current_dataset['group']]
              #            @datasets.push @current_dataset
              #          end
            end
            ##write new datasets.json
            File.open(dataset_file, 'w') do |f|
              f.write @h_datasets.to_json
            end
            
              #File.delete output_file
          elsif @h_json['list_groups'] and @h_json['list_groups'].size > 1
            @h_datasets = {}
            opt = []
            @list_datasets = []
            @h_json['list_groups'].each do |group|
              group['detected_format'] = @h_json['detected_format']
              opt = "-sel '" + group['group'] + "'"
              @h_datasets[opt] = group
              @list_datasets.push({'filename' => group['group']})
            end
            ##write new datasets.json                                                                                                                                                                                              
              File.open(dataset_file, 'w') do |f|
              f.write @h_datasets.to_json
            end
            
            ##write list_files.json                    
            File.open( filelist_file, 'w') do |f|
              f.write({'list_files' => @list_datasets}.to_json)
            end
            
          elsif @h_json['displayed_error']
            @error = @h_json['displayed_error']
          elsif @h_json['list_files'] and @h_json['list_files'].size > 1 ## it is a list of datasets
         
            ### re-write                                                                                                                                                                      
            File.open(output_file, 'w') do |fw|
              fw.write @h_json.to_json
            end

            ## move file
            @list_datasets = @h_json['list_files']
            FileUtils.cp output_file, filelist_file
            
            

            #File.open(filelist_file, 'w') do |f|
            #  f.write @list_datasets.to_json
            #end
         # elsif  @h_json['metadata']
         #   @current_dataset =  @h_json['metadata']
          end
        end
      else
        if File.exist?(upload_dir + 'output.err')
          err = File.read(upload_dir + 'output.err')
          @h_json = {"displayed_error" => err}
          File.open(output_file, 'w') do |fw|
            fw.write @h_json.to_json
          end
        end
      end
#      else
#        #-col first -o tutu -loom /data/asap2/users/1/06y2o7/parsing/output.loom -f /data/asap2/fus/24350/gene_annotation.txt  -header true -which gene
#        project = @fu.project 
#        project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + @project.user_id.to_s + @project.key
#        upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + @fu.id.to_s
#        filepath = upload_dir + @fu.upload_file_name

#        parsing_loom_file = project_dir + 'parsing' + 'output.loom' 
 ##       @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T PreparseMetadata #{options.join(" ")} -loom #{parsing_loom_file} -f \"#{filepath}\" -o #{upload_dir} -h localhost:5434/asap2_development"

 #        @res = `#{@cmd}`
 #       @h_json = nil
 #       if File.exist? output_file
 #       output_json = File.read output_file
 #         output_json.gsub!(/\s+/, ' ')
 #         @log+= output_json
#
#          if !output_json.empty?
#            logger.debug output_json
#            @h_json = JSON.parse(output_json)
#
#            ### record upload details if available                                                                                                            #  
#            if @h_json['detected_format'] and !params[:sel]
#              @h_upload_details = {
#                'detected_format' => @h_json['detected_format']
#              }
#              
#              File.open(upload_details_file, 'w') do |f|
#                f.write @h_upload_details.to_json
#              end
#            end
#            
#          end
        
   # end
      
    end
    
    render :partial => 'preparsing' 
  end

  # GET /fus
  # GET /fus.json
  def index
    if admin?
      @fus = Fu.all.order(name: :asc)
    elsif current_user
      @fus = Fu.where(:user_id => current_user.id).all.order(name: :asc)
    end
  end

  # GET /fus/1
  # GET /fus/1.json
  def show
    # If upload is not commenced or finished, redirect to upload page
    return redirect_to upload_fu_path(@fu) if @fu.status.in?(%w(new uploading))
  end

  # GET /fus/new
  def new
    @fu = Fu.new
  end

  # GET /fus/1/edit
  def edit
  end

  # POST /fus
  # POST /fus.json
  def create
    @fu = Fu.new(fu_params)
    @fu.status = 'new'

    respond_to do |format|
      if @fu.save
        format.html { redirect_to upload_fu_path(@fu), notice: 'Fu was successfully created.' }
        format.json { render :show, status: :created, location: @fu }
      else
        format.html { render :new }
        format.json { render json: @fu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fus/1
  # PATCH/PUT /fus/1.json
  def update
    @fu.assign_attributes(status: 'new', upload: nil) if params[:delete_upload] == 'yes'
    
    respond_to do |format|
      if @fu.update(fu_params)
        format.html { redirect_to @fu, notice: 'Fu was successfully updated.' }
        format.json { render :show, status: :ok, location: @fu }
      else
        format.html { render :edit }
        format.json { render json: @fu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fus/1
  # DELETE /fus/1.json
  def destroy
    if admin?
      @fu.destroy
      respond_to do |format|
        format.html { redirect_to fus_url, notice: 'Fu was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  # GET /fus/:id/upload
  def upload
    respond_to do |format|
      format.html { render :partial => 'upload' }
    end
  end

  # PATCH /fus/:id/upload.json
  def do_upload
   # upload_params[:upload]_file_name].gsub!(/[()\[\]\#\?\$]/, '')
    unpersisted_fu = Fu.new(upload_params)
    unpersisted_fu.upload_file_name.gsub!(/[()\[\]\#\?\$]/, '')
    @fu.upload_file_name.gsub!(/[()\[\]\#\?\$]/, '') if  @fu.upload_file_name
    # If no file has been uploaded or the uploaded file has a different filename,
    # do a new upload from scratch    
    if @fu.upload_file_name != unpersisted_fu.upload_file_name      
      @fu.assign_attributes(upload_params)
      @fu.upload_file_name.gsub!(/[()\[\]\#\?\$]/, '')
      @fu.status = 'uploading'
      @fu.save!
      render json: @fu.to_jq_upload and return

    # If the already uploaded file has the same filename, try to resume
    else
      current_size = @fu.upload_file_size
      content_range = request.headers['CONTENT-RANGE']
      begin_of_chunk = content_range[/\ (.*?)-/,1].to_i # "bytes 100-999999/1973660678" will return '100'

      # If the there is a mismatch between the size of the incomplete upload and the content-range in the
      # headers, then it's the wrong chunk! 
      # In this case, start the upload from scratch
      unless begin_of_chunk == current_size
        @fu.update!(upload_params)
        render json: @fu.to_jq_upload and return
      end
      
      # Add the following chunk to the incomplete upload
      logger.debug("write file to " + @fu.upload.path)
      File.open(@fu.upload.path, "ab") { |f| f.write(upload_params[:upload].read) }

      # Update the upload_file_size attribute
      @fu.upload_file_size = @fu.upload_file_size.nil? ? unpersisted_fu.upload_file_size : @fu.upload_file_size + unpersisted_fu.upload_file_size
      @fu.save!

      render json: @fu.to_jq_upload and return
    end
  end

  # GET /fus/:id/reset_upload
  def reset_upload
    # Allow users to delete uploads only if they are incomplete
    raise StandardError, "Action not allowed" unless @fu.status == 'uploading'
    @fu.update!(status: 'new', upload: nil)
    redirect_to @fu, notice: "Upload reset successfully. You can now start over"
  end

  # GET /fus/:id/resume_upload.json
  def resume_upload
    render json: { file: { name: @fu.upload.url(:default, timestamp: false), size: @fu.upload_file_size } } and return
  end

  # PATCH /fus/:id/update_upload_status
  def update_status
    raise ArgumentError, "Wrong status provided " + params[:status] unless @fu.status == 'uploading' && params[:status] == 'uploaded'
    @fu.update!(status: params[:status])
#    head :ok
    render json: @fu.to_jq_upload and return
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_fu
    @fu = Fu.find(params[:id])
    @project = @fu.project
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def fu_params
    params.require(:fu).permit(:name, :upload_type, :project_id, :project_key)
  end

  def upload_params
    params.require(:fu).permit(:upload)
  end
end
