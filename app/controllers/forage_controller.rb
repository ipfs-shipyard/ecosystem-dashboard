class ForageController < ApplicationController
  def index
    @internal_or_partner_package_ids = Package.internal.pluck(:id)
    @dependency_ids = RepositoryDependency.where(repository_id: Repository.internal.pluck(:id)).pluck(:package_id).compact
    @ids = (@internal_or_partner_package_ids + @dependency_ids).uniq
    @packages = Package.select('id, platform, name').where(platform: ['Go', 'Npm']).where(id: @ids)
    @json = @packages.map do |package|
      {
        manager: package.platform.downcase,
        name: package.name
      }
    end
    render json: @json.to_json
  end
end
