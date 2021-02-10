namespace :pmf do
  task states: :environment do
    state_name = 'high'
    start_date = 52.week.ago
    end_date = 50.week.ago
    window = 1 # week

    windows = Pmf.state(state_name, start_date, end_date, window)

    windows.sort_by{|d,a| d }.each do |date, actors|
      p date

      actors.sort_by{|a,e| -e.length }.first(10).each do |a, e|
        puts "  #{a} - #{e.length}"
      end
      puts
    end
  end
end
