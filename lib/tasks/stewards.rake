require 'csv'

namespace :stewards do
  task export_repos: :environment do

    exclude_fields = ['topics', 'direct_internal_dependency_package_ids', 'indirect_internal_dependency_package_ids']

    scope = Repository.internal
    csv_string = CSV.generate do |csv|
      csv << Repository.attribute_names.excluding(exclude_fields)
      scope.find_each(batch_size: 5000) do |repo|
        csv << repo.attributes.except(*exclude_fields).values
      end
    end

    puts csv_string
  end

  task export_events: :environment do

    scope = Event.internal.this_period(180).humans
    csv_string = CSV.generate do |csv|
      csv << Event.attribute_names.excluding("payload")
      scope.find_each(batch_size: 5000) do |event|
        csv << event.attributes.except("payload").values
      end
    end

    puts csv_string
  end
end
