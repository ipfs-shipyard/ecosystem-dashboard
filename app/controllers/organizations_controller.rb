class OrganizationsController < ApplicationController
  def internal
    @page_title = 'Internal Organizations'

    sort = params[:sort] || 'organizations.created_at'
    order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        scope = Issue.all

        if params[:range].present?
          scope = scope.where('issues.created_at > ?', params[:range].to_i.days.ago)
        end

        @orgs = Organization.internal.pluck(:name).map do |org|
          load_org_data(scope, org)
        end
      end
      format.rss do
        @scope = Organization.internal.order(sort => order)
        @pagy, @orgs = pagy(@scope)
        render 'index', :layout => false
      end
      format.json do
        @scope = Organization.internal.order(sort => order)
        @pagy, @orgs = pagy(@scope)
        render json: @orgs
      end
    end
  end

  def collabs
    @page_title = 'Collaborator Organizations'

    sort = params[:sort] || 'events_count'
    order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @scope = Organization.collaborator.order(sort => order)
        @pagy, @orgs = pagy(@scope, items: 100)
      end
      format.rss do
        @scope = Organization.collaborator.order(sort => order)
        @pagy, @orgs = pagy(@scope)
        render 'index', :layout => false
      end
      format.json do
        @scope = Organization.collaborator.order(sort => order)
        @pagy, @orgs = pagy(@scope)
        render json: @orgs
      end
    end
  end

  def active_collabs
    @page_title = 'Active Collaborators'

    sort = params[:sort] || 'events_count'
    order = params[:order] || 'desc'

    @period = (params[:range].presence || 7).to_i

    @active_collab_names = Organization.active_collabs(Event.internal.this_period(@period))

    @scope = Organization.where(name: @active_collab_names).order(sort => order)
    @pagy, @orgs = pagy(@scope, items: 100)

    respond_to do |format|
      format.html do
        render 'collabs'
      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @orgs
      end
    end
  end

  def show
    @organization = Organization.find_by_name!(params[:id])
    @period = (params[:range].presence || 30).to_i

    sort = params[:sort] || 'created_at'
    order = params[:order] || 'desc'

    @event_scope = Event.internal.user(@organization.pushing_contributor_names).not_core
    @issues_scope = Issue.internal.user(@organization.pushing_contributor_names).not_core
    @search_scope = SearchResult.includes(:search_query).where(org: @organization.name)

    @new_issues = @issues_scope.this_period(@period).issues.count
    @new_issues_last_week = @issues_scope.last_period(@period).issues.count

    @new_prs = @issues_scope.this_period(@period).pull_requests.count
    @new_prs_last_week = @issues_scope.last_period(@period).pull_requests.count

    @response_time = (@issues_scope.this_period(@period).unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time).to_i/60.0/60.0).round(1)
    @response_time_last_week = (@issues_scope.last_period(@period).unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time).to_i/60.0/60.0).round(1)

    @event_scope = @event_scope.this_period(@period)
    @search_scope = @search_scope.this_period(@period)
    @repos_count = Repository.org(@organization.name).active.source.count

    @repository_dependencies = @organization.repository_dependencies.internal.where(direct: true).active.source.includes(:repository, :manifest)

    case params[:tab]
    when 'search'
      @pagy, @results = pagy(@search_scope.order(sort => order))
    else
      @pagy, @events = pagy(@event_scope.order(sort => order))
    end
  end

  def dependencies
    @repositories = Repository.archived(false).fork(false).where('pushed_at > ?', 1.year.ago).org(params[:id])
    @dependencies = RepositoryDependency.internal.where(repository_id: @repositories.pluck(:id)).includes({package: :versions}, :repository, :manifest)
    @internal_packages = @dependencies.group_by(&:package).sort_by{|p,rd| [-rd.length, p.name] }
  end

  private

  def load_org_data(scope, org)
    {
      name: org,
      issues_count: scope.issues.org(org).count,
      open_issues_count: scope.issues.org(org).state('open').count,
      closed_issues_count: scope.issues.org(org).state('closed').count,
      pull_requests_count: scope.pull_requests.org(org).count,
      open_pull_requests_count: scope.pull_requests.org(org).state('open').count,
      closed_pull_requests_count: scope.pull_requests.org(org).state('closed').count,
      comments: scope.org(org).sum(:comments_count),
      contributors: scope.org(org).humans.core.group(:user).count.sort_by(&:last).reverse,
      community_contributors: scope.org(org).not_core.group(:user).count.sort_by(&:last).reverse,
      bots: scope.org(org).bots.group(:user).count.sort_by(&:last).reverse,
      repos: scope.org(org).group(:repo_full_name).count.sort_by(&:last).reverse
    }
  end
end
