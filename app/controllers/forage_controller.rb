class ForageController < ApplicationController
  def index
    @internal_or_partner_packages = Package.internal.pluck(:platform, :name)
    @dependencies = RepositoryDependency.where(repository_id: Repository.internal.pluck(:id)).pluck(:platform, :package_name).uniq
    @packages = (@internal_or_partner_packages + @dependencies).map{|p| [p[0].downcase, p[1]]}.uniq.select{|p| ['npm','go'].include? p[0]}
    @json = @packages.sort.map do |package|
      {
        manager: package[0].downcase,
        name: package[1]
      }
    end
    render json: @json.to_json
  end
end
