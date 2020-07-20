namespace :orgs do
  task update_counts: :environment do
    Organization.collaborator.each(&:update_counts)
  end
end
