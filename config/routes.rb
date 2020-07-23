Rails.application.routes.draw do

  mount PgHero::Engine, at: "pghero"

  resources :packages do
    collection do
      get :search
      get :outdated
    end
  end
  resources :repositories
  resources :contributors

  get 'search/collabs', to: 'search#collabs', as: :collabs_search
  get 'search/highlights', to: 'search#highlights', as: :highlights
  get 'search', to: 'search#index', as: :search
  get 'collabs/contributors', to: 'contributors#collabs', as: :collab_contributors
  get 'collabs/packages', to: 'packages#collabs', as: :collab_packages
  get 'collabs/repositories', to: 'repositories#collab_repositories', as: :collab_repositories
  get 'collabs/events', to: 'events#collabs', as: :collab_events
  get 'collabs/active', to: 'organizations#active_collabs', as: :active_collabs
  get 'collab_issues', to: 'issues#index', as: :collab_issues
  get 'events', to: 'events#index'
  get 'slow_response', to: 'issues#slow_response', as: :slow_response
  get 'weekly', to: redirect('/collab_issues?range=7')
  get 'collabs', to: 'organizations#collabs'
  get 'all', to: 'issues#all', as: :all_issues
  get 'orgs/:id/dependencies', to: 'organizations#dependencies', as: :org_dependencies
  get 'orgs/:id', to: 'organizations#show', as: :org
  get 'orgs', to: 'organizations#internal', as: :orgs
  get 'home', to: 'home#index'

  root to: 'home#index'
end
