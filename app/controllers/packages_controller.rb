class PackagesController < ApplicationController
  def index
    @scope = Package.all
    @pagy, @packages = pagy(@scope.order('dependent_repos_count DESC, dependents_count DESC, created_at DESC'))
  end

  def show
    @package = Package.find(params[:id])
  end
end
