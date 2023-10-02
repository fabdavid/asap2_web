class HomeController < ApplicationController

  layout "welcome"

  def unauthorized
    render "shared/unauthorized"
  end

  def get_file_index
    if current_user
      default_dir = "data/bachelor_2022"
      @dir = params[:dir] || default_dir 
    end
  end

  def get_file
#    response.headers["X-Accel-Redirect"]=  "/data/asap2/input.tab" #FB2020_05.sql.gz.05"
#    response.headers["X-Accel-Mapping"]=  "/data/asap2/=/rails_send_file/"
#    send_file "/data/asap2/FB2020_05.sql.gz.05", x_sendfile: true, buffer_size: 512
    path = "/rails_send_file/FB2020_05.sql.gz.05"
#    response.headers['X-Accel-Redirect'] = path
#    response.headers['X-Accel-Mapping'] = "/data/asap2/=/rails_send_file/"
#    response.headers['Content-Type'] = "application/force-download" 
#    response.headers['Content-Disposition'] = "attachment; toto"
#    response.headers['Content-Length'] = File.size "/data/asap2/FB2020_05.sql.gz.05"
    headers['Content-Disposition'] = "attachment; toto" 
    headers['X-Accel-Redirect'] = path #'/download_public/uploads/stories/' + params[:story_id] +'/' + params[:story_id] + '.zip'
   # send_file "/data/asap2/FB2020_05.sql.gz.05", :xsend_file => true
    render :nothing => true #, :disposition => 'attachment; toto'
  end

  def admin_page
  end

  def welcome
    @nber_public_projects = Project.where(:public => true).count
  end

  def orcid_authentication
  end

  def associate_orcid
    params[:client] ||= 'asap'
    if params[:code]

      if current_user and params[:client] == "asap"
        
        client_id = "APP-UIU8KR3XZNMUZ8ZY"
        secret = "0c8e89c1-9962-4cf9-9bdd-c7888f1b141b"
        res = `curl -L -k -H 'Accept: application/json' --data 'client_id=#{client_id}&client_secret=#{secret}&grant_type=authorization_code&redirect_uri=https://asap.epfl.ch/associate_orcid&code=#{params[:code]}' https://orcid.org/oauth/token`
        
        @h_res = Basic.safe_parse_json(res, {})
        
        
        h_orcid_user = {
          :key => @h_res['orcid'], 
          :name => @h_res['name']
        }
        orcid_user = OrcidUser.where(:key => h_orcid_user[:key]).first
        if !orcid_user
          orcid_user = OrcidUser.new(h_orcid_user)
          orcid_user.save
        else
          orcid_user.update_attributes(h_orcid_user)
        end
        
        if orcid_user and @h_res['orcid']
          current_user.update_attributes(:orcid_user_id => orcid_user.id) 
          notice = "ORCID successfully associated: #{@h_res['name']} [#{@h_res['orcid']}]"
        else
          notice = "ORCID user wasn't associated"
        end

        redirect_to :projects, :notice => notice
        
      else

        #        render :json => @h_res
        redirect_to  "https://reprosci.epfl.ch/associate_orcid?code=#{params[:code]}"
        
      end

    else
      notice = 'ORCID association failed'
      if params[:client] == "asap"
        render :json => {:error => notice}
      else
        redirect_to :projects, :notice => notice
      end
    end

  end

  def associate_orcid_reprosci
    params[:client] ||= 'reprosci'
    associate_orcid
  end

  def index

    if current_user
      redirect_to :projects
    else
      render
    end
    
  end

  def support
  end

  def citation
#     render :layout => false if params[:nolayout]
  end

  def about

  end

  def tutorial
    @h_tutos = {
      'getting_started' => "Tutorial 1 : Getting started - Welcome to ASAP!", 
      'full_pipeline' => "Tutorial 2 : Full pipeline on a project imported from the Human Cell Atlas",
      'cell_ranger' => "Tutorial 3 : How to import data from 10x [from CellRanger output]",
      'loom' => "Tutorial 4 : How to work with Loom files created by ASAP",
      'out_of_ram' => "Tutorial 5 : How to best select methods for avoiding out-of-RAM errors",
      'fca' => "Tutorial 6: How to use the visualization tools for interacting with the UMAP/t-SNE plots. An example using the Fly Cell Atlas"
      #,
      #      'importing_data' => "Importing data", 
      #      'project_details' => "Editing project details", 
      #      'public_projects' => "How to make your project public"
    }
    @h_icons = {
      'full_pipeline' => ['hca_logo.jpg', 'https://www.humancellatlas.org/'],
      'fca' => ['fca_logo.png', 'https://flycellatlas.org']
    }
    if params[:t]
      render "tutorial"
    else
      render "tutorial_list"
    end
#    render :layout => false if params[:nolayout]
  end

  def file_format
    @h_formats={}
    FileFormat.all.map{|f| @h_formats[f.name] = f}
    #    render :layout => false if params[:nolayout]
  end

  def faq
#    render :layout => false if params[:nolayout]
  end
  
  def test
#    render :layout => 'welcome'
  end

end
