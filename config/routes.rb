Rails.application.routes.draw do
  get 'collabs', to: 'issues#collabs'
  get 'all', to: 'issues#all'
  get 'orgs/:id', to: 'orgs#show', as: :org
  get 'orgs', to: 'orgs#protocol'


  root to: 'issues#index'
end
