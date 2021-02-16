class PmfRepo
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

    previous_repo_names = previously_active_repo_names(start_date)

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    windows = slice_events(events, window)

    periods = []

    previous_window = nil

    windows.sort_by{|d,e| d}.each_with_index do |window, i|
      date = window[0]
      window_events = window[1]

      previous_window_events = i.zero? ? [] : previous_window[1]

      states = states_for_window(window_events, previous_window_events, previous_repo_names)

      previous_repo_names += states.map{|a| a[0]}
      previous_repo_names.uniq!

      previous_window = window

      state_groups = Hash[states.group_by{|u| u[2]}.map{|s,u| [s, u.length]}]

      periods << {date: date, states: state_groups}
    end

    return periods[1..-1] # don't return the extra first period as it was only used for detecting first timers
  end

  def self.transitions(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    previous_repo_names = previously_active_repo_names(start_date)

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    windows = slice_events(events, window)

    periods = []

    previous_window = nil

    windows.sort_by{|d,e| d}.each_with_index do |window, i|
      date = window[0]
      window_events = window[1]

      previous_window_events = i.zero? ? [] : previous_window[1]

      states = states_for_window(window_events, previous_window_events, previous_repo_names)

      previous_repo_names += states.map{|a| a[0]}
      previous_repo_names.uniq!

      previous_window = window

      periods << {date: date, states: states}
    end

    # skip first window

    # for each window, compare states between repos and add to transition bucket
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

      previous_states = Hash[previous_period[:states].group_by{|u| u[2] }.map{|s,repos| [s, repos.map{|u| u[0] }]}]
      current_states = Hash[period[:states].group_by{|u| u[2] }.map{|s,repos| [s, repos.map{|u| u[0] }]}]

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

    previous_repo_names = previously_active_repo_names(start_date)

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    windows = slice_events(events, window)

    periods = []

    previous_window = nil

    windows.sort_by{|d,e| d}.each_with_index do |window, i|
      date = window[0]
      window_events = window[1]

      previous_window_events = i.zero? ? [] : previous_window[1]

      states = states_for_window(window_events, previous_window_events, previous_repo_names)

      previous_repo_names += states.map{|a| a[0]}
      previous_repo_names.uniq!

      previous_window = window

      state_groups = {}

      states.sort_by{|u| -u[1]}.each do |u|
        state_groups[u[2]] ||= []

        state_groups[u[2]] << {repo_full_name: u[0], score: u[1]}
      end

      periods << {date: date, states: state_groups}
    end
    return periods
  end

  def self.states_for_window(window_events, previous_window_events, previous_repo_names)
    # TODO use previous_window_events for transitions

    active_repository_full_names = window_events.group_by(&:repository_full_name)

    scores = active_repository_full_names.map{|repo_full_name, events| [repo_full_name, score_for_repo(repo_full_name, events)] }

    states = scores.map{|repo_full_name, score| [repo_full_name, score, state_for_repo(repo_full_name, score)] }

    these_repos = states.map{|a| a[0]}

    # repo from previous_repo_names not present here (inactive)
    inactive = previous_repo_names - these_repos
    states += inactive.map{|repo_full_name| [repo_full_name, 0, 'inactive'] }

    # repo not in previous_repo_names present here (first)
    first = these_repos - previous_repo_names

    states_with_firsts = states.map do |repo|
      if first.include?(repo[0])
        [repo[0], repo[1], 'first']
      else
        repo
      end
    end

    states_with_firsts
  end

  def self.score_for_repo(repo_full_name, events)
    # TODO this is were we can tweak the weights of various types, repos and orgs
    events.length
  end

  def self.state_for_repo(repo_full_name, score)
    # TODO maybe make these thresholds tweakable
    return 'high' if score >= 5
    return 'low' if score >= 1
    return 'inactive' if score.zero?
  end

  def self.load_event_data(start_date, end_date)
    # might want to exclude certain event types
    # excludes PL folk and bots
    event_scope.select('events.created_at, repository_full_name, actor').created_after(start_date).created_before(end_date).all
  end

  def self.slice_events(events, window)
    # TODO handle window for values other than 1
    events.group_by{ |e| e.created_at.beginning_of_week }
  end

  def self.previously_active_repo_names(before_date)
    event_scope.created_after(BACK_DATE).created_before(before_date).pluck(:repository_full_name).uniq
  end

  def self.event_scope
    # not star events
    # not PL employees/contractors
    # only repos with pl dependencies or search results or pl owned repos

    repository_ids = Repository.with_internal_deps.pluck(:id)
    repository_ids += Repository.with_search_results.pluck(:id)
    repository_ids -= Repository.internal.pluck(:id)
    repository_ids.uniq!

    Event.not_core.where.not(event_type: 'WatchEvent').where(repository_id: repository_ids)
  end
end
