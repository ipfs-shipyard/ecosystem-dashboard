namespace :pmf do
  task states: :environment do
    state_name = 'high'
    start_date = 52.week.ago
    end_date = 50.week.ago
    window = 1 # week

    windows = Pmf.state(state_name, start_date, end_date, window)

    windows.each do |window|
      puts window[:date]

      window[:states].each do |state, users|
        puts "  #{state}"
        users.first(5).each do |user|
          puts "    #{user[:username]} (#{user[:score]})"
        end
      end

      puts
    end
  end
end
