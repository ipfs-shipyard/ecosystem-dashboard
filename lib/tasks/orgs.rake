namespace :orgs do
  desc 'update count fields on collabortor organizations'
  task update_counts: :environment do
    Organization.collaborator.each(&:update_counts)
  end
end
