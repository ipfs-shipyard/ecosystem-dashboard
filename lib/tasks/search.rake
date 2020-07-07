namespace :search do
  task run_all: :environment do
    SearchQuery.run_all
  end
end
