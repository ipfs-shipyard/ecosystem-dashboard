class RepositoriesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:discover, :dependency_counts]

  def index
    @page_title = 'Internal Repositories'
    @scope = Repository.internal

    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?

    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @scope = @scope.topic(params[:topic]) if params[:topic].present?
    @scope = @scope.smart if params[:smart].present?

    @sort = params[:sort] || 'score'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).internal.group(:org).count
        @languages = @scope.unscope(where: :language).group(:language).count
        @topics = @scope.unscope(where: :topics).pluck(:topics).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
      end
      format.rss do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render json: @repositories
      end
    end
  end

  def show
    @repository = Repository.find_by_id(params[:id]) || Repository.find_by_full_name(params[:id])

    respond_to do |format|
      format.html do
        case params[:tab]
        when 'dependency_events'
          @dependency_events_pagy, @dependency_events = pagy(@repository.dependency_events.internal.where('committed_at <= ?', Time.now).order('dependency_events.committed_at DESC'), items: 150)
        when 'dependencies'
          @manifests = @repository.manifests.includes(repository_dependencies: {package: :versions}).order('kind DESC')
        when 'search'
          @results_pagy, @results = pagy(@repository.search_results.includes(:search_query).order('created_at DESC'))
        else
          @events_scope = Event.includes(:repository, :contributor).where.not(event_type: ['WatchEvent', 'MemberEvent', 'PublicEvent']).where(repository_id: @repository.id)
          @events_pagy, @events = pagy(@events_scope.order('events.created_at DESC'))
        end
      end
      format.json do
        render json: @repository
      end
    end
  end

  def collab_repositories
    @page_title = 'Collaborator Repositories'
    @scope = Repository.collaborator
    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @scope = @scope.topic(params[:topic]) if params[:topic].present?
    @scope = @scope.smart if params[:smart].present?

    if params[:dependent_org].present?
      org = Organization.find_by_name(params[:dependent_org])
      @scope = @scope.with_internal_deps_from_org(org.package_ids)
    else
      @scope = @scope.where('score >= 1')
    end

    @sort = params[:sort] || 'score'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).collaborator.group(:org).count
        @languages = @scope.unscope(where: :language).group(:language).count
        @topics = @scope.unscope(where: :topics).pluck(:topics).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
      end
      format.rss do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render json: @repositories
      end
    end
  end

  def community
    @page_title = 'Community Repositories'

    @scope = Repository.community.with_internal_deps
    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @scope = @scope.topic(params[:topic]) if params[:topic].present?
    @scope = @scope.smart if params[:smart].present?

    if params[:dependent_org].present?
      org = Organization.find_by_name(params[:dependent_org])
      @scope = @scope.with_internal_deps_from_org(org.package_ids)
    else
      @scope = @scope.where('score >= 1')
    end

    @sort = params[:sort] || 'score'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).community.group(:org).count
        @languages = @scope.unscope(where: :language).group(:language).count
        @topics = @scope.unscope(where: :topics).pluck(:topics).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
        render :collab_repositories
      end
      format.rss do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render json: @repositories
      end
    end
  end

  def map
    if params[:organization].present?
      @organization = Organization.find_by_name(params[:organization])
      @scope = @organization.repositories
    else
      @scope = Repository.internal
    end

    @scope = @scope.topic(params[:topic]) if params[:topic].present?

    @go = @scope.active.fork(false).where(language: 'Go').order('stargazers_count desc, pushed_at asc')
    @go_deps = RepositoryDependency.direct.where(package_id: Package.internal.platform('Go').pluck(:id)).includes(package: :repository)
    @go_deps_repos = @go_deps.map{|d| d.package.repository }.uniq
    @go_libs = @go.where(id: @go_deps_repos.pluck(:id)).includes(:packages)
    @user_go_libs = @go_libs.select{|r| r.packages.sum(&:dependent_repos_count) > 0 }
    @internal_go_libs = @go_libs.select{|r| r.packages.sum(&:dependent_repos_count).zero? }
    @go_tools = @go.where.not(id: @go_deps_repos.pluck(:id)).includes(:packages)

    @javascript = @scope.active.fork(false).where(language: ['JavaScript', 'TypeScript', 'CoffeeScript']).order('stargazers_count desc, pushed_at asc')
    @javascript_deps = RepositoryDependency.direct.where(package_id: Package.internal.platform('Npm').pluck(:id)).includes(package: :repository)
    @javascript_deps_repos = @javascript_deps.map{|d| d.package.repository }.uniq
    @javascript_libs = @javascript.where(id: @javascript_deps_repos.pluck(:id)).includes(:packages)
    @user_javascript_libs = @javascript_libs.select{|r| r.packages.sum(&:dependent_repos_count) > 0 }
    @internal_javascript_libs = @javascript_libs.select{|r| r.packages.sum(&:dependent_repos_count).zero? }
    @javascript_tools = @javascript.where.not(id: @javascript_deps_repos.pluck(:id)).includes(:packages)

    @documentation = @scope.active.fork(false).where(language: [nil, 'TeX']).order('stargazers_count desc, pushed_at asc')
    @websites = @scope.active.fork(false).where(language: ['HTML', 'CSS']).order('stargazers_count desc, pushed_at asc')
    @infrastructure = @scope.active.fork(false).where(language: ['Shell', 'Makefile', 'Dockerfile', 'HCL']).order('stargazers_count desc, pushed_at asc')
    @others = @scope.active.fork(false).where.not(language: ['Go', 'JavaScript', 'TypeScript', 'HTML', 'CSS', 'Shell', 'Makefile', 'Dockerfile', 'CoffeeScript', 'HCL', 'TeX']).order('stargazers_count desc, pushed_at asc')
    @forks = @scope.active.fork(true).order('stargazers_count desc, pushed_at asc')
    @archived = @scope.archived(true).order('stargazers_count desc, pushed_at asc')
  end

  def audit
    @scope = Repository.internal.active.source.preload(:release_events)

    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?

    @orgs = @scope.unscope(where: :org).internal.group(:org).count
    @languages = @scope.unscope(where: :language).group(:language).count

    @sort = params[:sort] || 'repositories.full_name'
    @order = params[:order] || 'asc'

    @repositories = @scope.order(@sort => @order).all
  end

  def states
    state_name = params[:tab].presence || 'first'

    parse_pmf_params

    respond_to do |format|
      format.html do
        @data = PmfRepo.state(state_name, @start_date, @end_date, @window, @threshold, @dependency_threshold)

        if @data
          all_repos = @data.first[:states].first[1]
        else
          all_repos = []
        end

        @pagy, @repositories = pagy_array(all_repos)
      end
      format.json do
        json = Rails.cache.fetch("repo_states-#{pmf_url_param_string}") do
          PmfRepo.states(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
        end
        render json: json
      end
    end
  end

  def transitions
    transition_name = params[:tab].presence || 'First Time'

    parse_pmf_params

    respond_to do |format|
      format.html do
        @data = PmfRepo.transitions_with_details(@start_date, @end_date, @window, @threshold, @dependency_threshold)

        if @data
          all_repos = @data.first[:transitions][transition_name.to_sym]
        else
          all_repos = []
        end

        @pagy, @repositories = pagy_array(all_repos)
      end
      format.json do
        json = Rails.cache.fetch("repo_transitions-#{pmf_url_param_string}") do
          PmfRepo.transitions_with_details(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
        end
        render json: json
      end
    end
  end

  def discover
    if params[:names].present?
      names = params[:names].split(',').map(&:strip)
      @existing_repositories = Repository.where(full_name: names)
      @missing_names = names - @existing_repositories.map(&:full_name)
      @new_repos = @missing_names.map do |name|
        if @missing_names.length > 1
          Repository.download_async(name, discovered: true)
          nil
        else
          Repository.download(name, discovered: true)
        end
      end.compact
      @remaining_missing_names = @missing_names - @new_repos.map(&:full_name)
      @repositories = @existing_repositories + @new_repos
    elsif params[:org].present?
      Repository.import_org(params[:org])
      @repositories = @existing_repositories = Repository.source.active.org(params[:org])
    end
    @existing_repositories.update_all(discovered: true) if @existing_repositories
    respond_to do |format|
      format.html
      format.json do
        render json: @repositories.to_json(methods: [:contributors_count, :direct_internal_dependency_counts, :indirect_internal_dependency_counts, :keyword_match_count])
      end
      format.rss do
        render 'index', :layout => false
      end
    end
  end

  def dependency_counts
    names = params[:names].split(',').map(&:strip)
    @existing_repositories = Repository.where(full_name: names)
    @missing_names = names - @existing_repositories.map(&:full_name)
    @missing_names.map do |name|
        Repository.download_async(name)
    end

    json = {}
    names.each do |name|
      repo = @existing_repositories.find{|r| r.full_name == name}
      if repo
        json[name] = (repo.direct_internal_dependency_package_ids + repo.indirect_internal_dependency_package_ids).uniq.length
      else
        json[name] = 0
      end
    end

    respond_to do |format|
      format.json do
        render json: json.to_json
      end
    end
  end

  def hackathons
    @scope = Repository.discovered.where(fork: false).order('created_at desc')
    @pagy, @repositories = pagy(@scope, items: 500)
  end

  def contributors
    @repository = Repository.find_by_id(params[:id]) || Repository.find_by_full_name(params[:id])
    @contributors = @repository.contributor_counts
    
    respond_to do |format|
      format.html do
        @pagy, @contributors = pagy_array(@contributors)
      end
      format.json do
        render json: @contributors.map{|name, count| {github_username: name, contribution_count: count} }
      end
    end
  end
end
