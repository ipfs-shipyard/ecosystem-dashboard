class RepositoryDownloadWorker
  include Sidekiq::Worker

  def perform(full_name_or_id, discovered)
    Repository.download(full_name_or_id, discovered: discovered)
  end
end
