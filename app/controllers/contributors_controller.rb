class ContributorsController < ApplicationController
  def index
    @range = (params[:range].presence || 7).to_i
    @issues_scope = Issue.internal.this_period(@range)

    if params[:org].present?
      @issues_scope = @issues_scope.org(params[:org])
    end

    @contributors = @issues_scope.not_core.unlocked.where("html_url <> ''").group(:user).count.sort_by{|k,v| -v}
  end

  def new
    @range = (params[:range].presence || 7).to_i
    @issues_scope = Issue.internal

    if params[:org].present?
      @issues_scope = @issues_scope.org(params[:org])
    end

    first_timers = (@issues_scope.this_period(@range).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - @issues_scope.where('issues.created_at < ?', @range.days.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys)
    @contributors = @issues_scope.not_core.unlocked.where("html_url <> ''").where(user: first_timers).group(:user).count.sort_by{|k,v| -v}
  end
end
