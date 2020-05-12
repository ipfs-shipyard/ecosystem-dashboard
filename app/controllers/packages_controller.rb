class PackagesController < ApplicationController
  def index
    @scope = Package.where(repository_id: Repository.protocol.pluck(:id)).includes(:repository)
    @pagy, @packages = pagy(@scope.order('collab_dependent_repos_count DESC, dependent_repos_count DESC, created_at DESC'))
  end

  def show
    @package = Package.find(params[:id])
  end
end
