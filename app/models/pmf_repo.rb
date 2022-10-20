class PmfRepo
  DEFAULT_WINDOW = 14
  DEFAULT_THRESHOLD = 5
  DEFAULT_DEPENDENCY_THRESHOLD = 1

  def self.state(state_name, start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    period_start_dates(start_date, end_date, window).map do |period_start_date|
      next if period_start_date.to_date < start_date.to_date
      period_end_date = calculate_end_date(period_start_date, window)
      states = states_for_window_dates(period_start_date, period_end_date, threshold_for_period(window, threshold), dependency_threshold)

      state_groups = {}

      states.sort_by{|u| [-u[1], u[0]]}.each do |u|
        next unless u[2] == state_name
        state_groups[u[2]] ||= []
        state_groups[u[2]] << {repo_name: u[0], score: u[1]}
      end

      {date: period_start_date, states: state_groups}
    end.compact
  end

  def self.states(start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    period_start_dates(start_date, end_date, window).map do |period_start_date|
      next if period_start_date.to_date < start_date.to_date
      period_end_date = calculate_end_date(period_start_date, window)
      states = states_for_window_dates(period_start_date, period_end_date, threshold_for_period(window, threshold), dependency_threshold)
      state_groups = {}

      states.sort_by{|u| [-u[1], u[0]]}.each do |u|
        state_groups[u[2]] ||= []
        state_groups[u[2]] << {repo_name: u[0], score: u[1]}
      end

      {date: period_start_date, states: state_groups}
    end.compact
  end

  def self.states_summary(start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    period_start_dates(start_date, end_date, window).map do |period_start_date|
      next if period_start_date.to_date < start_date.to_date
      period_end_date = calculate_end_date(period_start_date, window)
      states = states_for_window_dates(period_start_date, period_end_date, threshold_for_period(window, threshold), dependency_threshold)
      state_groups = Hash[states.group_by{|u| u[2]}.map{|s,u| [s, u.length]}]
      {date: period_start_date, states: state_groups}
    end.compact
  end

  def self.transitions(start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    period_dates = period_start_dates(start_date, end_date, window)

    if period_dates.length < 2
      # add extra period to the start of period_dates
      extra_date = period_dates.first - window
      period_dates = [extra_date, period_dates.first]
    end

    periods = period_dates.map do |period_start_date|
      period_end_date = calculate_end_date(period_start_date, window)
      states = states_for_window_dates(period_start_date, period_end_date, threshold_for_period(window, threshold), dependency_threshold)
      {date: period_start_date, states: states}
    end

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
          'First Time': current_states.fetch('first', []).length,
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

    return transition_periods
  end

  def self.transitions_with_details(start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    period_dates = period_start_dates(start_date, end_date, window)

    if period_dates.length < 2
      # add extra period to the start of period_dates
      extra_date = period_dates.first - window
      period_dates = [extra_date, period_dates.first]
    end

    periods = period_dates.map do |period_start_date|
      period_end_date = calculate_end_date(period_start_date, window)
      states = states_for_window_dates(period_start_date, period_end_date, threshold_for_period(window, threshold), dependency_threshold)
      {date: period_start_date, states: states}
    end

    # for each window, compare states between users and add to transition bucket
    previous_period = nil
    transition_periods = []

    # TODO if periods.length == 1 load an extra previous period

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

      previous_states = Hash[previous_period[:states].group_by{|u| u[2] }]
      current_states = Hash[period[:states].group_by{|u| u[2] }]

      bounced = compare_states_with_details(previous_states, current_states, 'first', 'inactive')
      new_low = compare_states_with_details(previous_states, current_states, 'first', 'low')
      new_high = compare_states_with_details(previous_states, current_states, 'first', 'high')
      reactive_low = compare_states_with_details(previous_states, current_states, 'inactive', 'low')
      low_high = compare_states_with_details(previous_states, current_states, 'low', 'high')
      high_low = compare_states_with_details(previous_states, current_states, 'high', 'low')
      reactive_high = compare_states_with_details(previous_states, current_states, 'inactive', 'high')
      lapsed_low = compare_states_with_details(previous_states, current_states, 'low', 'inactive')
      lapsed_high = compare_states_with_details(previous_states, current_states, 'high', 'inactive')
      high = compare_states_with_details(previous_states, current_states, 'high', 'high')
      low = compare_states_with_details(previous_states, current_states, 'low', 'low')
      inactive = compare_states_with_details(previous_states, current_states, 'inactive', 'inactive')

      transition_periods << {
        date: period[:date],
        transitions: {
          'First Time': (current_states['first'] || []).map{|u| {repo_name: u[0], score: u[1], previous: 0} },
          'Bounced': bounced,
          'New Low-Value': new_low,
          'New High-Value': new_high,
          'Reactivated Low-Value': reactive_low,
          'Low to High-Value': low_high,
          'High to Low-Value': high_low,
          'Lapsed Low-Value': lapsed_low,
          'Reactivated High-Value': reactive_high,
          'Lapsed High-Value': lapsed_high,
          'High-Value': high,
          'Low-Value': low,
          'Inactive': inactive
        }
      }
      previous_period = period
    end

    return transition_periods
  end

  def self.transition(transition_name, start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    periods = transitions(start_date, end_date, window, threshold, dependency_threshold)
    periods.map do |period|
      {
        date:  period[:date],
        transitions: period[:transitions].slice(transition_name.to_sym)
      }
    end
  end

  def self.transition_with_details(transition_name, start_date, end_date, window = DEFAULT_WINDOW, threshold = nil, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    periods = transitions_with_details(start_date, end_date, window, threshold, dependency_threshold)
    periods.map do |period|
      {
        date:  period[:date],
        transitions: period[:transitions].slice(transition_name.to_sym)
      }
    end
  end

  private

  def self.period_start_dates(start_date, end_date, window)
    case window
    when 'week'
      (start_date.to_date..end_date.to_date).map(&:beginning_of_week).uniq
    when 'month'
      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq
    else
      # x number of days rolling backwards from end_date until start_date
      start_dates = []
      next_start_date = (end_date.to_date - window).to_date
      while next_start_date > (start_date.to_date - window) # include one extra week to get first_timers
        start_dates << next_start_date
        next_start_date = (next_start_date.to_date - window).to_date
      end
      start_dates.reverse
    end
  end

  def self.threshold_for_period(window, threshold = nil)
    case window
    when 'week'
      threshold || DEFAULT_THRESHOLD
    when 'month'
      threshold || (DEFAULT_THRESHOLD*4.3).round
    else
      threshold || ((DEFAULT_THRESHOLD/7.0)*window.to_i).round
    end
  end

  def self.calculate_end_date(start_date, window)
    case window
    when 'week'
      start_date + 1.week
    when 'month'
      start_date + 1.month
    else
      start_date.to_date + window
    end
  end

  def self.compare_states(previous_states, current_states, previous_group, current_group)
    prev = previous_states[previous_group] || []
    curr = current_states[current_group] || []
    prev & curr
  end

  def self.compare_states_with_details(previous_states, current_states, previous_group, current_group)
    prev = previous_states[previous_group] || []
    curr = current_states[current_group] || []
    names = prev.map(&:first) & curr.map(&:first)
    curr.select{|u| names.include?(u[0])}.sort_by{|u| [-u[1], u[0]] }.map do |u|
      pscore = prev.find{|pu| pu[0] == u[0] }.try(:second) || 0
      {repo_name: u[0], score: u[1], previous: pscore}
    end
  end

  def self.states_for_window_dates(start_date, end_date, threshold, dependency_threshold)
    Rails.cache.fetch(['pmf_repo_states_for_window_dates', threshold, dependency_threshold, start_date, end_date], expires_in: 1.week) do
      puts "Generating cache for #{start_date} - #{end_date} (threshold:#{threshold}, dependency_threshold:#{dependency_threshold})"
      previous_repo_names = previously_active_repo_names(start_date, dependency_threshold)
      repository_ids = repo_ids(end_date, dependency_threshold)
      active_repos = {}

      repository_ids.each_slice(10000) do |ids|
        print "."
        active_repos.merge!(Event.where(pmf: true).where(repository_id: ids).select('repository_full_name').created_after_date(start_date).created_before_date(end_date).group(:repository_full_name).count(:id))
      end

      puts "active_repos: #{active_repos.keys.length}"

      dep_removed_repo_names = Repository.where(full_name: active_repos.keys).where('last_internal_dep_removed < ?', end_date).pluck(:full_name)

      states = active_repos.map do |repo_name, score|
        if dep_removed_repo_names.include?(repo_name)
          # inactive if not/stopped using dependencies in this period
          [repo_name, 0, 'inactive']
        else
          [repo_name, score, state_for_repo(repo_name, score, threshold)]
        end
      end

      these_repos = states.map{|a| a[0]}

      # repo from previous_repo_names not present here (inactive)
      inactive = previous_repo_names - these_repos
      states += inactive.map{|repo_name| [repo_name, 0, 'inactive'] }

      # repo not in previous_repo_names present here (first)
      first = these_repos - previous_repo_names

      states.map do |repo|
        first.include?(repo[0]) ? [repo[0], repo[1], 'first'] : repo
      end
    end
  end

  def self.score_for_repo(repo_name, events)
    # TODO this is were we can tweak the weights of various types, repos and orgs
    events
  end

  def self.state_for_repo(repo_name, score, threshold = DEFAULT_THRESHOLD)
    return 'high' if score >= threshold.to_i
    return 'low' if score >= 1
    return 'inactive' if score.zero?
  end

  def self.load_event_data(start_date, end_date, dependency_threshold)
    
  end

  def self.previously_active_repo_names(before_date, dependency_threshold)
    repo_names = repo_names(before_date, dependency_threshold).sort
    all_active_repo_names = PmfActiveRepoDate.where('date <= ?', before_date).pluck(:repository_full_names).flatten.sort.uniq
    all_active_repo_names & repo_names
  end

  def self.pl_orgs
    ['protocol', 'ipfs', 'ipfs-shipyard', 'ipld', 'protoschool', 'libp2p',
      'ipfs-cluster', 'multiformats', 'ipfs-inactive', 'filecoin-project',
      'filecoin-shipyard', 'slate-engineering', 'web3-storage', 'nftstorage',
      'application-research', 'ipfs-examples', 'ipfs-elastic-provider']
  end

  def self.event_scope(end_date, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    # not star events
    # not PL employees/contractors
    # only repos with pl dependencies or pl owned repos
    repository_ids = repo_ids(end_date, dependency_threshold)

    Event.where(pmf: true).where(repository_id: repository_ids)
  end

  def self.repo_names(end_date, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    if dependency_threshold == 1
      repo_names = Repository.where('first_added_internal_deps < ?', end_date).pluck(:full_name)
    else
      # temp fallback if dependency_threshold greater than 1
      repo_names = Repository.with_internal_deps(dependency_threshold).pluck(:full_name)
    end

    # repository_ids += Repository.with_search_results.pluck(:full_name)
    repo_names -= Repository.internal.pluck(:full_name)
    repo_names -= Repository.org(pl_orgs).pluck(:full_name)
    repo_names
  end

  def self.repo_ids(end_date, dependency_threshold = DEFAULT_DEPENDENCY_THRESHOLD)
    if dependency_threshold == 1
      repository_ids = Repository.where('first_added_internal_deps < ?', end_date).pluck(:id)
    else
      # temp fallback if dependency_threshold greater than 1
      repository_ids = Repository.with_internal_deps(dependency_threshold).pluck(:id)
    end

    # repository_ids += Repository.with_search_results.pluck(:id)
    repository_ids -= Repository.internal.pluck(:id)
    repository_ids -= Repository.org(pl_orgs).pluck(:id)
    repository_ids
  end
end
