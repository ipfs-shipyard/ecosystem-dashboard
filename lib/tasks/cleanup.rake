namespace :cleanup do
  desc "Cleanup repositories"
  task repos: :environment do
    Repository.community.without_internal_deps.find_each(&:destroy)
  end

  desc "vacuum"
  task vacuum: :environment do
    begin
      tables = ActiveRecord::Base.connection.tables
      tables.each do |table|
        ActiveRecord::Base.connection.execute("VACUUM FULL ANALYZE #{table};")
      end
    rescue Exception => exc
      Rails.logger.error("Database VACUUM error: #{exc.message}")
    end
  end
end
