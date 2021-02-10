namespace :pmf do
  task states: :environment do
    state_name = 'high'
    start_date = 52.week.ago
    end_date = 50.week.ago
    window = 1 # week

    windows = Pmf.state(state_name, start_date, end_date, window)

    windows.sort_by{|d,a| d }.each do |date, actors|
      p date

      actors.group_by{|a| a[2]}.sort_by{|s,a| s}.each do |state, a|
        puts "  #{state} (#{a.length})"
        a.sort_by{|a| -a[0] }.first(10).each do |actor|
          puts "    #{actor[0]} - #{actor[1]}"
        end
      end

      puts
    end
  end
end
