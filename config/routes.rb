Rails.application.routes.draw do
  resources :project_types
  resources :project_cell_sets
  resources :annot_cell_sets
  resources :cell_sets
  resources :docker_images
  resources :docker_versions
  resources :cla_votes
  resources :project_tags
  resources :tmp_fos
  resources :clas do
    member do
      post :vote
    end
  end
  resources :cla_sources
  resources :cell_ontology_terms do 
    collection do
      get :autocomplete
    end
  end
  resources :cell_ontologies
  resources :orcid_users
  resources :output_attrs
  resources :attr_outputs
  resources :attr_names
  resources :ips do
  end
  #  resources :services
  resources :docker_patches
  resources :exp_entry_identifiers
  resources :tools
  resources :data_classes
  resources :exp_entries do 
      member do
      get :summary
    end
  end
  resources :provider_projects do
    collection do
      get :hca_index
    end
  end
  resources :providers
  resources :journals
  resources :articles do
    member do
      get :summary
    end
  end
  resources :identifier_types 
  resources :sample_identifiers
  resources :geo_entries do
    member do
      get :summary
    end
  end
#  resources :hca_projects
  resources :hcao_namespaces
  resources :hcao_terms
  resources :ensembl_subdomains
  resources :tmp_genes
  resources :gene_set_items do
    collection do
      get :search
    end
  end
  resources :archive_statuses
  resources :fos
  resources :todo_types
  resources :todo_votes
  resources :todos do
    collection do
      get :get_roadmap
      post :add_del_thumb
    end
  end
  resources :annots do
    member do
      get :get_cats
      get :get_cat_details
      get :get_cat_legend
    end
    collection do
    end
  end
  resources :data_types
  resources :upload_types
  resources :del_runs
  resources :active_runs
  resources :reqs
  resources :runs do
    member do
      get :get_de_gene_list
      get :get_ge_geneset_list
    end
  end
  resources :supports
  resources :std_methods
  resources :std_runs
  resources :correlations
  resources :trajectories
  resources :covariates
  resources :heatmaps
  resources :cell_filterings
  resources :gene_filterings
  resources :file_formats
  resources :comments
  resources :figures
  resources :filterings
  resources :normalizations
  resources :imputations
  resources :imputation_methods
  resources :genes do
    collection do
      get :check
      get :search
      get :autocomplete
    end
  end

  resources :fus do
    member do
      get 'upload', to: 'fus#upload'
      patch 'upload', to: 'fus#do_upload'
      get 'resume_upload', to: 'fus#resume_upload'
      patch 'update_status', to: 'fus#update_status'
      get 'reset_upload', to: 'fus#reset_upload'
      post 'retrieve_data_from_url'
      post 'preparsing'
    end
  end

  resources :dim_reductions
  resources :gene_sets do
    collection do
      get :autocomplete
    end
  end

  resources :gene_enrichments do
    member do
      get :get_list
    end
    collection do
      post :filter_results
    end
  end

  resources :project_dim_reductions
  resources :filter_methods
  resources :norms
  resources :diff_exprs do
    member do
      get :list_genes
      get :get_selection
    end
    collection do
      post :filter_results
    end
  end

  resources :selections
  resources :clusters do
    member do
      get :to_tab
    end
  end
  
  resources :shares do
    collection do
      post :batch_add
    end
  end
  resources :statuses
  resources :steps
  resources :versions do
    collection do
      get :last_version
    end
    member do
      get :run_stats
    end
  end
  resources :home do
    collection do
      get :get_file_index
      get :welcome
      get :identifiers
      get :test
      get :get_file
      get :about
      get :file_format
      get :tutorial
      get :faq
      get :citation
      get :support
      get :associate_orcid
      get :associate_orcid_reprosci
      get :orcid_authentication
      get :admin_page
    end
  end
  resources :organisms
 # devise_for :users
  devise_for :users, controllers: { sessions: "users/sessions", registrations: 'users/registrations' }
  resources :projects, param: :key do
    collection do
      post :upload_file
      get :get_cart
      get :form_select_input_data
      post :hca_preview
      get :hca_projects
      post :hca_download
      get :search_form
      get :search
      post :do_search
      post :set_search_session
      post :upd_project_tag
    end
    member do
      post :upd_marker_genes
      get :get_marker_gene_stats
      post :upd_gene_expr_stats
      get :del_gene
      post :compute_module_score
      get :get_annot_info
      post :upd_pred
      get :instructions
      get :get_loom_files_json
      post :set_public
      get :get_commands
      get :form_new_analysis
      get :form_new_metadata
      post :save_metadata_from_selection
      post :do_import_metadata
      post :upd_cat_alias
      post :upd_sel_cats
      post :broadcast_on_project_channel
      get :live_upd
      get :parse_form
      patch :parse
      post :set_lineage_run_ids
      get :get_cells
      get :upload_form
      post :prepare_metadata
      get :add_metadata
      get :get_step
      get :get_step_header
      get :get_run
      get :get_lineage
      get :get_file
      get :tsv_from_json
      get :edit_name
      get :get_pipeline
      get :get_attributes
      get :get_attribute
      get :set_input_data
      get :set_geneset
      get :get_visualization
      get :get_autocomplete_genes
      get :get_dim_reduction_form
      get :get_cell_scatter_form
      get :dr_plot
      get :cell_scatter_plot
      get :get_dr_options
      get :get_scp_options
      get :autocomplete_genes
      get :autocomplete_gene_set_items
      get :extract_row
      get :get_rows
      get :extract_metadata
      post :filter_de_results
      post :filter_ge_results
      get :clone
      post :delete_all_runs_from_step
      get :confirm_delete
      post :replot
 #     get :summary
      get :get_clusters
      post :cluster_comparison
      get :get_selections
      get :set_viz_session
      post :delete_batch_file
      post :direct_download
      get :save_plot_settings
    end
  end

  resources :project_steps
  resources :jobs

  # error pages      
#  %w( 404 422 500 503 ).each do |code|
#    get code, :to => "errors#show", :code => code
#  end


  match '/associate_orcid' => 'home#associate_orcid', :via => [:get]
  match '/associate_orcid2' => 'home#associate_orcid_reprosci', :via => [:get]

  match '/orcid_authentication' => 'home#orcid_authentication', :via => [:get]
  match '/roadmap' => 'todos#index', :via => [:get]
  match 'hca_projects' => 'provider_projects#hca_index', :via => [:get]
  match 'fca' => 'providers#fca', :via => [:get]
  match 'hca' => 'providers#hca', :via => [:get]
  match '/unauthorized' => 'home#unauthorized', :via => [:get]
  root 'projects#index'


end
