require 'csv'

namespace :contributions do
  task research: :environment do
    counts = Issue.not_core.group(:user).count

    # CSV.open("data/contributors.csv", "w") do |csv|

    csv_string = CSV.generate do |csv|
      csv << [
        'name',
        'Contributions',
        'First response'
      ]

      counts.each do |row|
        next if row.first == 'ghost'
        resp = Issue.where(user: row.first).order('created_at ASC').first.response_time
        if resp
          csv << [
            row.first,
            row.last,
            (resp/3600.0).round(1)
          ]
        end
      end
    end
  end
end
