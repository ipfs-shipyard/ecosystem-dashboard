require 'csv'

namespace :contributors do
  task research: :environment do
    contributors = Issue.not_core.group(:user).count.sort_by{|u,c| -c}.select{|u,c| c > 10 }.reject{|u,c| u == 'ghost'}

    collabs = {}

    contributors.each do |username, contributions|
      collabs[username] = Issue.where(user: username).first.collabs
    end


    csv_string = CSV.generate do |csv|
      csv << [
        'Name',
        'Login',
        'Company',
        'URL',
        'Blog',
        'Location',
        'Bio',
        'Email',
        'Twitter',
        'Hireable',
        'Followers',
        'Contributions',
        'Collabs'
      ]

      contributors.each do |username, contributions|
        begin
          json = Issue.github_client.user(username)
          next if ['@protocol', 'Protocol Labs'].include?(json.company)
          csv << [
            json.name,
            username,
            json.company,
            "https://github.com/#{username}",
            json.blog,
            json.location,
            json.bio,
            json.email,
            json.twitter,
            json.hireable,
            json.followers,
            contributions,
            collabs[username].join(',')
          ]
        rescue Octokit::NotFound
          puts "#{username} DELETED"
        end
      end
    end

    puts csv_string
  end
end
