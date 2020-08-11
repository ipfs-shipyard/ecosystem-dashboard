namespace :repositories do
  task discover_from_search_results: :environment do
    Repository.discover_from_search_results
  end

  task recalculate_scores: :environment do
    Repository.recalculate_scores
  end

  task sync: :environment do
    Repository.order('last_sync_at ASC nulls first').limit(100).find_each(&:sync)
  end
end
