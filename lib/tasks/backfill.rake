require 'open-uri'
require 'zlib'

namespace :backfill do
  task all: :environment do

    org_names = Organization.internal.pluck(:name)
    if ENV['START_DATE'].present?
      start_date = Time.parse(ENV['START_DATE'])
    else
      start_date = Repository.internal.order('repositories.created_at asc').first.created_at

    end
    start_year = start_date.year
    start_year = 2015 if start_year < 2015

    if ENV['END_DATE'].present?
      end_date = Date.parse(ENV['END_DATE'])
    else
      end_date = Date.today
    end

    end_year = end_date.year

    (start_year..end_year).each do |year|
      (1..12).each do |month|
        max_days = Date.new(year, month, -1).day
        month = month.to_s.rjust(2, "0")

        (1..max_days).each do |day|
          day = day.to_s.rjust(2, "0")
          break if Date.parse("#{day}/#{month}/#{year}") > end_date

          if Date.parse("#{day}/#{month}/#{year}") > start_date

            (0..23).each do |hour|
              puts "#{day}/#{month}/#{year}/#{hour}"

              gz =  URI.open("http://data.gharchive.org/#{year}-#{month}-#{day}-#{hour}.json.gz")
              js = Zlib::GzipReader.new(gz).read

              Oj.load(js) do |event|
                repo_name = event['repo']['name']
                org = repo_name.split('/').first
                if org_names.include?(org)

                  repository = Repository.find_by_full_name(repo_name)
                  if repository
                    ret = Event.record_event(repository, event)
                    if ret
                      puts "#{repo_name} - #{event['type']}"
                    end
                  end

                end
              end
            end
          end
        end
      end
    end
  end
end
