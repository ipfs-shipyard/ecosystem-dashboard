class Pmf
  DEFAULT_WINDOW = 1 # week
  BACK_DATE = DateTime.parse('01/01/2021')

  def self.state(state_name, start_date, end_date, window = DEFAULT_WINDOW)
    periods = load_periods(start_date, end_date, window = DEFAULT_WINDOW)

    periods = periods.map do |period|
      {
        date:  period[:date],
        states: period[:states].slice(state_name)
      }
    end

    return periods[1..-1] # don't return the extra first period as it was only used for detecting first timers
  end

  def self.states_summary(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    previous_usernames = previously_active_usernames(start_date)

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    windows = slice_events(events, window)

    periods = []

    previous_window = nil

    windows.sort_by{|d,e| d}.each_with_index do |window, i|
      date = window[0]
      window_events = window[1]

      previous_window_events = i.zero? ? [] : previous_window[1]

      states = states_for_window(window_events, previous_window_events, previous_usernames)

      previous_usernames += states.map{|a| a[0]}
      previous_usernames.uniq!

      previous_window = window

      state_groups = Hash[states.group_by{|u| u[2]}.map{|s,u| [s, u.length]}]

      periods << {date: date, states: state_groups}
    end

    return periods[1..-1] # don't return the extra first period as it was only used for detecting first timers
  end

  def self.transitions(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    previous_usernames = previously_active_usernames(start_date)

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    windows = slice_events(events, window)

    periods = []

    previous_window = nil

    windows.sort_by{|d,e| d}.each_with_index do |window, i|
      date = window[0]
      window_events = window[1]

      previous_window_events = i.zero? ? [] : previous_window[1]

      states = states_for_window(window_events, previous_window_events, previous_usernames)

      previous_usernames += states.map{|a| a[0]}
      previous_usernames.uniq!

      previous_window = window

      periods << {date: date, states: states}
    end

    # skip first window

    # for each window, compare states between users and add to transition bucket
    previous_period = nil
    transition_periods = []

    periods.each_with_index do |period,i|
      if i.zero?
        previous_period = period
        next
      end
      # note - not calculating 11 -	Never Used

      # 1 	First Time               (currently in first)

      # 2 	Bounced                  (first -> inactive)
      # 3 	New Low-Value            (first -> low)
      # 4 	New High-Value           (first -> high)
      # 5 	Reactivated Low-Value    (inactive -> low)
      # 6 	Low to High-Value        (low -> high)
      # 7 	High to Low-Value        (high -> low)
      # 8 	Lapsed Low-Value         (low -> inactive)
      # 9 	Reactivated High-Value   (inactive -> high)
      # 10 	Lapsed High-Value        (high -> inactive)
      # 12 	High-Value               (high -> high)
      # 13 	Low-Value                (low -> low)
      # 14 	Inactive                 (inactive -> inactive)

      previous_states = Hash[previous_period[:states].group_by{|u| u[2] }.map{|s,users| [s, users.map{|u| u[0] }]}]
      current_states = Hash[period[:states].group_by{|u| u[2] }.map{|s,users| [s, users.map{|u| u[0] }]}]

      bounced = compare_states(previous_states, current_states, 'first', 'inactive')
      new_low = compare_states(previous_states, current_states, 'first', 'low')
      new_high = compare_states(previous_states, current_states, 'first', 'high')
      reactive_low = compare_states(previous_states, current_states, 'inactive', 'low')
      low_high = compare_states(previous_states, current_states, 'low', 'high')
      high_low = compare_states(previous_states, current_states, 'high', 'low')
      reactive_high = compare_states(previous_states, current_states, 'inactive', 'high')
      lapsed_low = compare_states(previous_states, current_states, 'low', 'inactive')
      lapsed_high = compare_states(previous_states, current_states, 'high', 'inactive')
      high = compare_states(previous_states, current_states, 'high', 'high')
      low = compare_states(previous_states, current_states, 'low', 'low')
      inactive = compare_states(previous_states, current_states, 'inactive', 'inactive')

      transition_periods << {
        date: period[:date],
        transitions: {
          'First Time': current_states['first'].length,
          'Bounced': bounced.length,
          'New Low-Value': new_low.length,
          'New High-Value': new_high.length,
          'Reactivated Low-Value': reactive_low.length,
          'Low to High-Value': low_high.length,
          'High to Low-Value': high_low.length,
          'Lapsed Low-Value': lapsed_low.length,
          'Reactivated High-Value': reactive_high.length,
          'Lapsed High-Value': lapsed_high.length,
          'High-Value': high.length,
          'Low-Value': low.length,
          'Inactive': inactive.length
        }
      }
      previous_period = period
    end

    return transition_periods # don't return the extra first period as it was only used for detecting first timersTODO
  end

  def self.transition(transition_name, start_date, end_date, window = DEFAULT_WINDOW)
    periods = transitions(start_date, end_date, window)
    periods.map do |period|
      {
        date:  period[:date],
        transitions: period[:transitions].slice(transition_name.to_sym)
      }
    end
  end

  def self.compare_states(previous_states, current_states, previous_group, current_group)
    prev = previous_states[previous_group] || []
    curr = current_states[current_group] || []
    prev & curr
  end

  def self.load_periods(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    previous_usernames = previously_active_usernames(start_date)

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    windows = slice_events(events, window)

    periods = []

    previous_window = nil

    windows.sort_by{|d,e| d}.each_with_index do |window, i|
      date = window[0]
      window_events = window[1]

      previous_window_events = i.zero? ? [] : previous_window[1]

      states = states_for_window(window_events, previous_window_events, previous_usernames)

      previous_usernames += states.map{|a| a[0]}
      previous_usernames.uniq!

      previous_window = window

      state_groups = {}

      states.sort_by{|u| -u[1]}.each do |u|
        state_groups[u[2]] ||= []

        state_groups[u[2]] << {username: u[0], score: u[1]}
      end

      periods << {date: date, states: state_groups}
    end
    return periods
  end

  def self.states_for_window(window_events, previous_window_events, previous_usernames)
    # TODO use previous_window_events for transitions

    active_actors = window_events.group_by(&:actor)

    scores = active_actors.map{|username, events| [username, score_for_user(username, events)] }

    states = scores.map{|username, score| [username, score, state_for_user(username, score)] }

    these_users = states.map{|a| a[0]}

    # user from previous_usernames not present here (inactive)
    inactive = previous_usernames - these_users
    states += inactive.map{|username| [username, 0, 'inactive'] }

    # user not in previous_usernames present here (first)
    first = these_users - previous_usernames

    states_with_firsts = states.map do |user|
      if first.include?(user[0])
        [user[0], user[1], 'first']
      else
        user
      end
    end

    states_with_firsts
  end

  def self.score_for_user(username, events)
    # TODO this is were we can tweak the weights of various types, repos and orgs
    events.length
  end

  def self.state_for_user(username, score)
    # TODO maybe make these thresholds tweakable
    return 'high' if score >= 5
    return 'low' if score >= 1
    return 'inactive' if score.zero?
  end

  def self.load_event_data(start_date, end_date)
    # might want to exclude certain event types
    # excludes PL folk and bots
    event_scope.select('events.created_at, actor').created_after(start_date).created_before(end_date).all
  end

  def self.slice_events(events, window)
    # TODO handle window for values other than 1
    events.group_by{ |e| e.created_at.beginning_of_week }
  end

  def self.previously_active_usernames(before_date)
    event_scope.created_after(BACK_DATE).created_before(before_date).pluck(:actor).uniq
  end

  def self.event_scope
    Event.not_core.where.not(event_type: 'WatchEvent')
  end
end
