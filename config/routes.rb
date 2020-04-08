Rails.application.routes.draw do

  mount PgHero::Engine, at: "pghero"

  get 'collabs', to: 'issues#collabs'
  get 'all', to: 'issues#all'
  get 'orgs/:id', to: 'orgs#show', as: :org
  get 'orgs', to: 'orgs#protocol'


  root to: 'issues#index'
end
