class ContributorsController < ApplicationController
  def index
    @range = (params[:range].presence || 7).to_i
    @issues_scope = Issue.internal.this_period(@range).not_core.unlocked.where("html_url <> ''")

    @issues_scope = @issues_scope.org(params[:org]) if params[:org].present?
    @collabs = @issues_scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
    @issues_scope = @issues_scope.collab(params[:collab]) if params[:collab].present?

    @scope = @issues_scope.group(:user).count.sort_by{|k,v| -v}
    @pagy, @contributors = pagy_array(@scope)

    respond_to do |format|
      format.html do

      end
      format.json do
        render json: @contributors
      end
    end
  end

  def new
    @range = (params[:range].presence || 7).to_i
    @issues_scope = Issue.internal.not_core.unlocked.where("html_url <> ''")

    @issues_scope = @issues_scope.org(params[:org]) if params[:org].present?
    @collabs = @issues_scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
    @issues_scope = @issues_scope.collab(params[:collab]) if params[:collab].present?

    first_timers = (@issues_scope.this_period(@range).group(:user).count.keys - @issues_scope.where('issues.created_at < ?', @range.days.ago).group(:user).count.keys)
    @scope = @issues_scope.where(user: first_timers).group(:user).count.sort_by{|k,v| -v}
    @pagy, @contributors = pagy_array(@scope)

    respond_to do |format|
      format.html do

      end
      format.json do
        render json: @contributors
      end
    end
  end

  def collabs
    @range = (params[:range].presence || 7).to_i
    @issues_scope = Issue.internal.this_period(@range).all_collabs.unlocked.where("html_url <> ''")

    @issues_scope = @issues_scope.org(params[:org]) if params[:org].present?
    @collabs = @issues_scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
    @issues_scope = @issues_scope.collab(params[:collab]) if params[:collab].present?

    @scope = @issues_scope.group(:user).count.sort_by{|k,v| -v}
    @pagy, @contributors = pagy_array(@scope)

    respond_to do |format|
      format.html do

      end
      format.json do
        render json: @contributors
      end
    end
  end

  def show
    @contributor = params[:id]
    @events = Event.internal.user(@contributor).limit(10).order('events.created_at desc')
    @issues = Issue.internal.user(@contributor).limit(10).order('issues.created_at desc')

    respond_to do |format|
      format.html do

      end
      format.json do
        render json: {
          events: @events,
          issues: @issues
        }
      end
    end
  end
end
