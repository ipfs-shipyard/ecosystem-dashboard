class DependencyEventsWorker
  include Sidekiq::Worker

  def perform(repo_id)
    Repository.find_by_id(repo_id).try(:mine_dependencies)
  end
end
