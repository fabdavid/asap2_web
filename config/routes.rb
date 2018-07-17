Rails.application.routes.draw do
  resources :projects
  resources :project_steps
  resources :jobs
  root 'projects#index'
end
