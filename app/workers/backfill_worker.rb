require 'open-uri'
require 'zlib'

class BackfillWorker
  include Sidekiq::Worker

  def perform(year, month, day, hour)
    repo_names = Repository.not_internal.with_internal_deps.pluck(:full_name)

    # do something
    gz =  URI.open("http://data.gharchive.org/#{year}-#{month}-#{day}-#{hour}.json.gz")
    json = Zlib::GzipReader.new(gz).read

    Oj.load(json) do |event|
      repo_name = event['repo']['name']
      if repo_names.include?(repo_name)
        repository = Repository.find_by_full_name(repo_name)
        Event.record_event(repository, event)if repository
      end
    end
  end
end
