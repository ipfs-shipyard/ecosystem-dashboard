class VersionsController < ApplicationController
  def index
    @package = Package.find(params[:package_id])
    @versions = @package.versions.sort

    respond_to do |format|
      format.html
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @versions
      end
    end
  end

  def show
    @package = Package.find(params[:package_id])
    @version = @package.versions.find(params[:id])
  end
end
