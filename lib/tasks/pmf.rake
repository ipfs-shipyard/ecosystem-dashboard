namespace :pmf do
  desc "list pmf states summary"
  task states: :environment do
    start_date = 6.week.ago
    end_date = 2.week.ago
    window = 7

    windows = Pmf.states_summary(start_date, end_date, window)
    windows.each do |window|
      puts window[:date]

      window[:states].each do |state, users|
        puts "  #{state} (#{users})"
      end

      puts
    end
  end

  desc "list pmf transitions summary"
  task transitions: :environment do
    start_date = 6.week.ago
    end_date = 2.week.ago
    window = 7

    windows = Pmf.transitions(start_date, end_date, window)
    windows.each do |window|
      puts window[:date]

      window[:transitions].each do |transition, users|
        puts "  #{transition} (#{users})"
      end

      puts
    end
  end

  desc "calculate pmf windows for past year from yesterday"
  task warm_caches: :environment do
    # run this via cron just after midnight
    # calculate pmf windows for past year from yesterday
    end_date = Date.yesterday - 3
    start_date = Date.today - (7*52)

    host = "#{ENV['DISPLAY_NAME'].downcase}.ecosystem-dashboard.com"

    paths = []

    [7,14,30,90].each do |window|
      puts [start_date, end_date, window].join('-')

      paths += [
        "/pmf/repo/transitions.json?start_date=#{start_date.to_s}&window=#{window}",
        "/pmf/repo/states.json?start_date=#{start_date.to_s}&window=#{window}"
      ]
  
      if ENV['DISPLAY_NAME'] == 'IPFS'
        paths += [
          "/pmf/repo/combined/states.json?start_date=#{start_date.to_s}&window=#{window}",
          "/pmf/repo/combined/transitions.json?start_date=#{start_date.to_s}&window=#{window}"
        ]
      end
      
      PmfRepo.transitions(start_date, end_date, window)
      PmfRepo.states(start_date, end_date, window)
      PmfRepo.states_summary(start_date, end_date, window)
    end

    paths.each do |path|
      Faraday.get("https://#{host}#{path}")
    end

  end

  desc 'rengerate pmf active repo dates'
  task regenerate: :environment do
    PmfActiveRepoDate.regenerate_recent
  end
end
