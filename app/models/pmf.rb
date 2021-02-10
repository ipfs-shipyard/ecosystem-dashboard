class Pmf
  DEFAULT_WINDOW = 1 # week

  def self.state(state_name, start_date, end_date, window = DEFAULT_WINDOW)
    return unless window >= 1

    start_date_with_extra_window = start_date - window.week

    events = load_event_data(start_date_with_extra_window, end_date)

    # slice event data into windows
      # for each window
        # group events by actor
        # for each actor
          # calculate their state

    windows = slice_events(events, window)

    periods = []

    windows.each_with_index do |window, i|
      date = window[0]
      e = window[1]

      states = states_for_window(e)

      periods << [date, states]
    end

    return periods
  end

  def self.transition(transition_number, start_date, end_date, window = DEFAULT_WINDOW)

  end

  def self.states_for_window(e)
    # TODO needs previous window too
    active_actors = e.group_by(&:actor)

    # TODO do a thing with each active_actor to calculate low or high

    # TODO compare with previous window for possible first timers, reactivators and inactives
  end

  def self.load_event_data(start_date, end_date)
    # might want to exclude certain event types
    # excludes PL folk and bots
    Event.not_core.created_after(start_date).created_before(end_date).all
  end

  def self.slice_events(events, window)
    # TODO handle window for values other than 1
    events.group_by{ |e| e.created_at.beginning_of_week }
  end
end
