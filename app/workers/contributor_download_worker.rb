class ContributorDownloadWorker
  include Sidekiq::Worker

  def perform(github_username)
    Contributor.download(github_username)
  end
end
