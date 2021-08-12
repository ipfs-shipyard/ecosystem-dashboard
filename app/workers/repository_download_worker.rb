class RepositoryDownloadWorker
  include Sidekiq::Worker

  def perform(full_name_or_id)
    Repository.download(full_name_or_id)
  end
end
