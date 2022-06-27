namespace :cleanup do
  desc "Cleanup repositories"
  task repos: :environment do
    Repository.community.where('first_added_internal_deps is null and last_internal_dep_removed is null').find_each do |repo|
      repo.events.delete_all
      repo.destroy
    end

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
