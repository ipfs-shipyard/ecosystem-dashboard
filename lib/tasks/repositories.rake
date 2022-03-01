namespace :repositories do
  desc "import new repositories discovered searching github "
  task discover_from_search_results: :environment do
    Repository.discover_from_search_results
  end

  desc "update ecosystem score for each repository"
  task recalculate_scores: :environment do
    Repository.recalculate_scores
  end

  desc "update 1200 least recently synced repositories"
  task sync: :environment do
    Repository.order('last_events_sync_at ASC nulls first').limit(1000).each(&:sync_if_updates)
    Repository.order('last_sync_at ASC nulls first').limit(200).each(&:sync)
  end

  desc "import 200 new repositories from discovered contributor events to other repos"
  task sync_discovered: :environment do
    all_names = Repository.discovered_related_repo_names
    existing_names = Repository.where(full_name: all_names).pluck(:full_name)
    missing_names = all_names - existing_names
    missing_names.shuffle.first(200).each do |name|
      Repository.download_async(name)
    end
  end
end
