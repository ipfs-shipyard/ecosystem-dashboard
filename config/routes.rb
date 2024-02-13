require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web, at: "sidekiq"
  mount PgHero::Engine, at: "pghero"

  get :admin, to: redirect('/admin/contributors')

  namespace :admin do
    resources :contributors
    resources :organizations
  end

  resources :packages do
    resources :versions
    collection do
      get :search
      get :outdated
    end
  end
  resources :repositories, constraints: { id: /.*/ } do
    collection do
      get :audit
      get :states
      get :transitions
      post :dependency_counts
    end
    member do
      get :contributors
    end
  end

  resources :contributors

  get :login,  to: 'sessions#new'
  get :logout, to: 'sessions#destroy'

  scope :auth do
    match '/:provider/callback', to: 'sessions#create',  via: [:get, :post]
    match :failure,              to: 'sessions#failure', via: [:get, :post]
  end

  get 'issues/review_requested', to: 'issues#review_requested'
  post 'issues/:id/sync', to: 'issues#sync', as: :sync_issue

  get 'forage', to: 'forage#index'

  get 'hackathons', to: 'repositories#hackathons'
  get 'hackathons/users', to: 'users#hackathons'

  get 'discover', to: 'repositories#discover'
  post 'discover', to: 'repositories#discover'

  get 'community/packages', to: 'packages#community', as: :community_packages
  get 'community/repositories', to: 'repositories#community', as: :community_repositories

  get 'map', to: 'repositories#map'

  get 'newsletter', to: 'events#newsletter'

  get 'search/collabs', to: 'search#collabs', as: :collabs_search
  get 'search/highlights', to: 'search#highlights', as: :highlights
  get 'search', to: 'search#index', as: :search
  get 'collabs/contributors', to: 'contributors#collabs', as: :collab_contributors
  get 'collabs/packages', to: 'packages#collabs', as: :collab_packages
  get 'collabs/repositories', to: 'repositories#collab_repositories', as: :collab_repositories
  get 'collabs/events', to: 'events#collabs', as: :collab_events
  get 'collabs/active', to: 'organizations#active_collabs', as: :active_collabs
  get 'collab_issues', to: 'issues#index', as: :collab_issues
  get 'events/all', to: 'events#all', as: :all_events
  get 'events', to: 'events#index'
  get 'slow_response', to: 'issues#slow_response', as: :slow_response
  get 'weekly', to: redirect('/collab_issues?range=7')
  get 'collabs', to: 'organizations#collabs'
  get 'all', to: 'issues#all', as: :all_issues
  get 'orgs/overview', to: 'organizations#overview', as: :org_overview
  get 'orgs/:id/dependencies', to: 'organizations#dependencies', as: :org_dependencies
  get 'orgs/:id', to: 'organizations#show', as: :org
  get 'orgs', to: 'organizations#internal', as: :orgs
  get 'home', to: 'home#index'
  get 'sitemap', to: 'home#sitemap'

  root to: 'home#index'
end
