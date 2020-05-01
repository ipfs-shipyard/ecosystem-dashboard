Rails.application.routes.draw do

  mount PgHero::Engine, at: "pghero"

  resources :packages
  resources :repositories

  get 'events', to: 'repositories#events'
  get 'slow_response', to: 'issues#slow_response'
  get 'weekly', to: 'issues#weekly'
  get 'collabs', to: 'issues#collabs'
  get 'all', to: 'issues#all'
  get 'orgs/:id', to: 'orgs#show', as: :org
  get 'orgs', to: 'orgs#protocol'


  root to: 'issues#index'
end
