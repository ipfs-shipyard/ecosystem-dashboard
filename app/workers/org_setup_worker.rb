class OrgSetupWorker
  include Sidekiq::Worker

  def perform(id)
    Organization.find(id).try(:setup)
  end
end
