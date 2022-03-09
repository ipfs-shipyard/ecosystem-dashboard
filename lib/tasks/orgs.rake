namespace :orgs do
  desc 'update count fields on collabortor organizations'
  task update_counts: :environment do
    Organization.collaborator.each(&:update_counts)
  end

  desc 'setup and sync repositories for all orgs'
  task setup: :environment do
    Organization.internal.each(&:setup_async)
  end
end
