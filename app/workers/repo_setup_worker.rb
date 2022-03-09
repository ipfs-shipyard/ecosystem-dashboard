class RepoSetupWorker
  include Sidekiq::Worker

  def perform(id)
    Repository.find(id).try(:setup)
  end
end
