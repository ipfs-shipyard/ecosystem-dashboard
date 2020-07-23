class IssuesController < ApplicationController
  def index
    redirect_to url_for(request.params.merge(only_collabs: true, action: :all))
  end

  def all
    @page_title = "Issues and Pull Requests"
    @range = (params[:range].presence || 30).to_i

    @scope = Issue.internal.humans.unlocked.this_period(@range).includes(:contributor).where("html_url <> ''")

    apply_filters

    respond_to do |format|
      format.html do
        @types = {
          'issues' => @scope.issues.count,
          'pull_requests' => @scope.pull_requests.count
        }

        @languages = Issue::LANGUAGES.to_h do |language|
          [language, @scope.unscope(where: :language).language(language).count]
        end

        @pagy, @issues = pagy(@scope.order(@sort => @order))

        @users = @scope.group(:user).count
        @states = @scope.unscope(where: :state).group(:state).count
        @repos = @scope.unscope(where: :repo_full_name).group(:repo_full_name).count
        @orgs = @scope.unscope(where: :org).internal.group(:org).count
        @labels = @scope.unscope(where: :labels).pluck(:labels).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
        @collabs = @scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
      end
      format.rss do
        @pagy, @issues = pagy(@scope.order(@sort => @order))

        render 'all', :layout => false
      end
      format.json do
        @pagy, @issues = pagy(@scope.order(@sort => @order))
        render json: @issues
      end
    end
  end

  def slow_response
    @page_title = "Slow Responses"
    @range = (params[:range].presence || 7).to_i
    @date_range = @range + 2
    @orginal_scope = Issue.internal.not_core.unlocked.where("html_url <> ''").not_draft.includes(:contributor)
    @scope = @orginal_scope.where('issues.created_at > ?', @date_range.days.ago).where('issues.created_at < ?', 2.days.ago)
    apply_filters

    respond_to do |format|
      format.html do
        @types = {
          'issues' => @scope.issues.count,
          'pull_requests' => @scope.pull_requests.count
        }
        @languages = Issue::LANGUAGES.to_h do |language|
          [language, @scope.unscope(where: :language).language(language).count]
        end

        @users = @scope.group(:user).count
        @states = @scope.unscope(where: :state).group(:state).count
        @repos = @scope.unscope(where: :repo_full_name).group(:repo_full_name).count
        @orgs = @scope.unscope(where: :org).internal.group(:org).count
        @labels = @scope.unscope(where: :labels).pluck(:labels).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
        @collabs = @scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }

        @orginal_scope = @orginal_scope.where(repo_full_name: params[:repo_full_name]) if params[:repo_full_name].present?
        @orginal_scope = @orginal_scope.org(params[:org]) if params[:org].present?

        name = params[:repo_full_name] || params[:org] || 'All Internal Orgs'

        @response_times = [
          {
            name: name,
            data: @orginal_scope.where.not(response_time: nil).where('issues.created_at > ?', 1.year.ago).group_by_week('issues.created_at').average(:response_time).map do |k,v|
              if v
                [k,(v/60.0/60.0).round(1)]
              else
                [k,nil]
              end
            end
          }
        ]

        @slow = @scope.slow_response

        @pagy, @issues = pagy(@slow.order(@sort => @order))

        @collabs = @slow.all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v }
        @labels = @slow.unscope(where: :labels).pluck(:labels).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
        @users = @slow.group(:user).count

      end
      format.rss do
        @slow = @scope.slow_response

        @pagy, @issues = pagy(@slow.order(@sort => @order))

        render 'all', :layout => false
      end
      format.json do
        @slow = @scope.slow_response

        @pagy, @issues = pagy(@slow.order(@sort => @order))
        render json: @issues
      end
    end

  end

  private

  def apply_filters
    @scope = @scope.exclude_user(params[:exclude_user]) if params[:exclude_user].present?
    @scope = @scope.exclude_repo(params[:exclude_repo_full_name]) if params[:exclude_repo_full_name].present?
    @scope = @scope.exclude_org(params[:exclude_org]) if params[:exclude_org].present?
    @scope = @scope.exclude_language(params[:exclude_language]) if params[:exclude_language].present?
    @scope = @scope.exclude_collab(params[:exclude_collab]) if params[:exclude_collab].present?
    @scope = @scope.exclude_label(params[:exclude_label]) if params[:exclude_label].present?
    @scope = @scope.not_core if params[:exclude_core].present?

    @scope = @scope.not_draft unless params[:include_drafts].present?

    @scope = @scope.where(comments_count: 0) if params[:uncommented].present?

    @scope = @scope.no_milestone if params[:no_milestone].present?

    @scope = @scope.unlabelled if params[:unlabelled].present?
    @scope = @scope.label(params[:label]) if params[:label].present?

    @scope = @scope.where(user: params[:user]) if params[:user].present?
    @scope = @scope.where(state: params[:state]) if params[:state].present?
    @scope = @scope.where(repo_full_name: params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.no_response if params[:no_response].present?
    @scope = @scope.collab(params[:collab]) if params[:collab].present?
    @scope = @scope.all_collabs if params[:only_collabs].present?

    @scope = @scope.language(params[:language]) if params[:language].present?

    if params[:type].present?
      if params[:type] == 'issues'
        @scope = @scope.issues
      else
        @scope = @scope.pull_requests
      end
    end

    @sort = params[:sort] || 'issues.created_at'
    @order = params[:order] || 'desc'
  end
end
