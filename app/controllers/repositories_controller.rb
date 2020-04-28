class RepositoriesController < ApplicationController
  def index
    @scope = Repository.protocol
    @pagy, @repositories = pagy(@scope.order('pushed_at DESC'))
  end
end
