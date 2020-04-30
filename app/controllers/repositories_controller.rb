class RepositoriesController < ApplicationController
  def index
    @scope = Repository.protocol
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @pagy, @repositories = pagy(@scope.order('pushed_at DESC'))

    @orgs = @scope.unscope(where: :org).protocol.group(:org).count
    @languages = @scope.unscope(where: :language).group(:language).count
  end
end
