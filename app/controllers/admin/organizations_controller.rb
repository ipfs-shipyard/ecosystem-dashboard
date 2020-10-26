class Admin::OrganizationsController < Admin::ApplicationController
  def index
    @scope = Organization.order('created_at DESC').where('collaborator IS true or internal IS true')
    @pagy, @orgs = pagy(@scope)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    if @organization.save
      redirect_to admin_organizations_path
    else
      render :new
    end
  end

  def edit
    @organization = Organization.find_by_name(params[:id])
  end

  def update
    @organization = Organization.find_by_name(params[:id])
    if @organization.update(organization_params)
      redirect_to admin_organizations_path
    else
      render :edit
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :internal, :collaborator, :docker_hub_org)
  end
end
