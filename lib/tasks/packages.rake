namespace :packages do
  task sync_internal: :environment do
    Package.internal.find_each(&:sync)
  end
end
