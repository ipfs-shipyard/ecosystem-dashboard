class Admin::ContributorsController < Admin::ApplicationController
  def index
    @scope = Contributor.order('created_at DESC')
    @pagy, @contributors = pagy(@scope)
  end

  def new
    @contributor = Contributor.new
  end

  def create
    @contributor = Contributor.new(contributor_params)
    if @contributor.save
      redirect_to admin_contributors_path
    else
      render :new
    end
  end

  def edit
    @contributor = Contributor.find(params[:id])
  end

  def update
    @contributor = Contributor.find(params[:id])
    if @contributor.update(contributor_params)
      redirect_to admin_contributors_path
    else
      render :edit
    end
  end

  private

  def contributor_params
    params.require(:contributor).permit(:github_username, :core, :bot)
  end
end
