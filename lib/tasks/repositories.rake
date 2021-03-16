namespace :repositories do
  task discover_from_search_results: :environment do
    Repository.discover_from_search_results
  end

  task recalculate_scores: :environment do
    Repository.recalculate_scores
  end

  task sync: :environment do
    Repository.not_internal.with_internal_deps.order('last_events_sync_at ASC nulls first').limit(500).each(&:sync_if_updates)
    Repository.order('last_sync_at ASC nulls first').limit(200).each(&:sync)
  end
end
