class RepositoriesController < ApplicationController
  def index
    @scope = Repository.all
    @pagy, @repositories = pagy(@scope.order('pushed_at DESC'))
  end
end
