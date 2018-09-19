Rails.application.routes.draw do
  resources :comments
  resources :figures
  resources :filterings
  resources :normalizations
  resources :imputations
  resources :imputation_methods
  resources :genes do
    collection do
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
  
  resources :shares
  resources :statuses
  resources :steps
  resources :versions do
    collection do
      get :last_version
    end
  end
  resources :home do
    collection do
      get :test
      get :about
      get :file_format
      get :tutorial
      get :faq
      get :citation
    end
  end
  resources :organisms
  devise_for :users
  resources :projects, param: :key do
    collection do
      post :upload_file
      get :get_cart
    end
    member do
      get :get_cells
      get :upload_form
      get :get_step
      get :get_file
      get :edit_name
      get :get_pipeline
      get :get_attributes
      get :get_visualization
      get :clone
      post :replot
      get :get_clusters
      get :get_selections
      get :set_viz_session
      post :delete_batch_file
      post :direct_download
    end
  end


  resources :project_steps
  resources :jobs
  root 'projects#index'
end
