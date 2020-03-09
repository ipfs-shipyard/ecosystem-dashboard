Rails.application.routes.draw do
  get 'collabs', to: 'issues#collabs'
  get 'all', to: 'issues#all'

  root to: 'issues#index'
end
