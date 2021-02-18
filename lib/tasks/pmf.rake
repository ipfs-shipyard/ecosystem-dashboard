namespace :pmf do
  task states: :environment do
    start_date = 6.week.ago
    end_date = 2.week.ago
    window = 1 # week

    windows = Pmf.states_summary(start_date, end_date, window)
    windows.each do |window|
      puts window[:date]

      window[:states].each do |state, users|
        puts "  #{state} (#{users})"
      end

      puts
    end
  end

  task transitions: :environment do
    start_date = 6.week.ago
    end_date = 2.week.ago
    window = 1 # week

    windows = Pmf.transitions(start_date, end_date, window)
    windows.each do |window|
      puts window[:date]

      window[:transitions].each do |transition, users|
        puts "  #{transition} (#{users})"
      end

      puts
    end
  end
end
