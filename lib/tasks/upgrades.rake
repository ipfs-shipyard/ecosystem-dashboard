require 'csv'

namespace :upgrades do
  task search: :environment do
    search_to_csv(["update ipfs is:issue", "update ipfs is:pr", "upgrade ipfs is:issue", "upgrade ipfs is:pr", "bump ipfs", "ipfs 0.5", "go-ipfs", "ipfs docker"], 'ipfs')
  end
end

def search_to_csv(queries, filename)
  CSV.open("data/#{filename}.csv", "w") do |csv|

    csv << [
      'Kind',
      'Created',
      'Owner',
      'Repository',
      'Number',
      'Author',
      'Comments',
      'URL',
      'Title',
      'Labels',
      'State'
    ]

    search_to_rows(queries).each do |row|
      csv << row
    end
  end
end

def search_to_rows(queries)
  queries = Array(queries)
  client = Issue.github_client

  rows = []

  queries.each do |query|
    search = client.search_issues("#{query} created:>2020-01-01 in:title", sort: 'created', order: 'asc')
    puts "#{query} had #{search[:total_count]} results" if search[:total_count] > 1000
    search[:items].each do |i|
      url = i[:html_url]
      state = i["state"]
      kind = 'Issue'
      repo = i[:repository_url].gsub('https://api.github.com/repos/', '')
      owner = repo.split('/').first

      next if Issue::INTERNAL_ORGS.include?(owner)

      if i[:pull_request].present?
        kind = 'Pull Request'
        pr = client.get(i[:pull_request][:url])
        url = pr[:html_url]
        state = 'merged' if pr[:merged]
      end

      rows << [
        kind,
        i[:created_at],
        owner,
        repo,
        i[:number],
        i[:user][:login],
        i[:comments],
        url,
        i[:title],
        i[:labels].map{|l| l[:name]}.join(','),
        state
      ]
    end
  end

  rows.uniq.sort_by{|r| r[1] }
end
