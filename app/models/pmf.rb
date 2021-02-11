class Pmf
  DEFAULT_WINDOW = 1 # week
  BACK_DATE = DateTime.parse('01/01/2021')

  def self.state(state_name, start_date, end_date, window = DEFAULT_WINDOW)
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

    return periods[1..-1] # don't return the extra first period as it was only used for detecting first timers
  end

  def self.transition(transition_number, start_date, end_date, window = DEFAULT_WINDOW)
    # TODO
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
    Event.not_core.select('events.created_at, actor').created_after(start_date).created_before(end_date).all
  end

  def self.slice_events(events, window)
    # TODO handle window for values other than 1
    events.group_by{ |e| e.created_at.beginning_of_week }
  end

  def self.previously_active_usernames(before_date)
    Event.created_after(BACK_DATE).not_core.created_before(before_date).pluck(:actor).uniq
  end
end
