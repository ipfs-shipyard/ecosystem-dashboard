namespace :search do
  desc 'peform all search queries'
  task run_all: :environment do
    SearchQuery.run_all
  end
end
