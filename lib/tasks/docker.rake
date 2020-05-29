require 'csv'

namespace :docker do
  task search: :environment do
    client = Issue.github_client
    search = client.search_code("filename:Dockerfile ipfs")

    CSV.open("data/docker.csv", "w") do |csv|

      csv << [
        'Owner',
        'Repository',
        'Path',
        'sha'
      ]

      search[:items].each do |result|
        next if ['x0rzkov/dockerfiles-dataset', 'GPC-debug/dockerfiles-search-1'].include?(result[:repository][:full_name])
        csv << [
          result[:repository][:full_name].split('/').first,
          result[:repository][:full_name],
          result[:path],
          result[:sha],
        ]
      end
    end
  end

  task augment_docker: :environment do
    client = Issue.github_client
    repos = {}
    rows = []
    CSV.foreach("data/docker.csv", headers: true).with_index(1) do |row, i|
      repos[row['Repository']] = client.repository(row['Repository']) unless repos[row['Repository']]
      rows << row
    end

    CSV.open("data/docker-2.csv", "w") do |csv|
      csv << [
        'Owner',
        'Repository',
        'Description',
        'Created',
        'Updated',
        'Language',
        'Archived',
        'Fork',
        'Stars',
        'Path',
        'sha'
      ]

      rows.each do |row|
        next if ['x0rzkov/dockerfiles-dataset', 'GPC-debug/dockerfiles-search-1'].include?(row[1])
        csv << [
          row[0],
          row[1],
          repos[row[1]][:description],
          repos[row[1]][:created_at],
          repos[row[1]][:updated_at],
          repos[row[1]][:language],
          repos[row[1]][:archived],
          repos[row[1]][:fork],
          repos[row[1]][:stargazers_count],
          row[2],
          row[3],
        ]
      end
    end
  end

  task search_compose: :environment do
    client = Issue.github_client

    search = client.search_code("filename:docker-compose ipfs")

    CSV.open("data/docker-compose.csv", "w") do |csv|

      csv << [
        'Owner',
        'Repository',
        'Path',
        'sha'
      ]

      search[:items].each do |result|
        csv << [
          result[:repository][:full_name].split('/').first,
          result[:repository][:full_name],
          result[:path],
          result[:sha],
        ]
      end
    end
  end

  task augment_compose: :environment do
    client = Issue.github_client
    repos = {}
    rows = []
    CSV.foreach("data/docker-compose.csv", headers: true).with_index(1) do |row, i|
      repos[row['Repository']] = client.repository(row['Repository']) unless repos[row['Repository']]
      rows << row
    end

    CSV.open("data/docker-compose-2.csv", "w") do |csv|
      csv << [
        'Owner',
        'Repository',
        'Description',
        'Created',
        'Updated',
        'Language',
        'Archived',
        'Fork',
        'Stars',
        'Path',
        'sha'
      ]

      rows.each do |row|
        csv << [
          row[0],
          row[1],
          repos[row[1]][:description],
          repos[row[1]][:created_at],
          repos[row[1]][:updated_at],
          repos[row[1]][:language],
          repos[row[1]][:archived],
          repos[row[1]][:fork],
          repos[row[1]][:stargazers_count],
          row[2],
          row[3],
        ]
      end
    end
  end
end
