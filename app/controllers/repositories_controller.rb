class RepositoriesController < ApplicationController
  def index
    @scope = Repository.internal
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @pagy, @repositories = pagy(@scope.order('repositories.pushed_at DESC'))

    @orgs = @scope.unscope(where: :org).internal.group(:org).count
    @languages = @scope.unscope(where: :language).group(:language).count
  end

  def events
    @scope = Event.includes(:repository).internal.where('events.created_at > ?', 1.month.ago).humans
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.user(params[:user]) if params[:user].present?
    @scope = @scope.repo(params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.event_type(params[:event_type]) if params[:event_type].present?
    @pagy, @events = pagy(@scope.order('events.created_at DESC'))

    @orgs = @scope.unscope(where: :org).internal.group(:org).count
    @repos = @scope.unscope(where: :repository_full_name).internal.group(:repository_full_name).count
    @users = @scope.unscope(where: :actor).humans.group(:actor).count
    @event_types = @scope.unscope(where: :event_type).group(:event_type).count
  end

  def show
    @repository = Repository.find(params[:id])
    @manifests = @repository.manifests.includes(repository_dependencies: {package: :versions}).order('kind DESC')
  end

  def collab_events
    @scope = Event.includes(:repository).external.where('events.created_at > ?', 1.month.ago).humans
    @scope = @scope.search(params[:query]) if params[:query].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.user(params[:user]) if params[:user].present?
    @scope = @scope.repo(params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.event_type(params[:event_type]) if params[:event_type].present?
    @pagy, @events = pagy(@scope.order('events.created_at DESC'))

    @orgs = @scope.unscope(where: :org).external.group(:org).count
    @repos = @scope.unscope(where: :repository_full_name).external.group(:repository_full_name).count
    @users = @scope.unscope(where: :actor).humans.group(:actor).count
    @event_types = @scope.unscope(where: :event_type).group(:event_type).count
  end
end
