class PackagesController < ApplicationController
  def state
    # start date
    # end date
    # state
    # window length

    # load event data between start and end dates
    # note: load one extra window to find first timers

    # slice event data into windows
      # for each window
        # group events by actor
        # for each actor
          # calculate their state

    PMF.state(params[:state_name], params[:start_date], params[:end_date], params[:window])
  end

  def transition
    # start date
    # end date
    # transition
    # window length

    # load event data between start and end dates
    # note: load one extra window to find first timers

    # slice event data into windows
      # for each window
        # group events by actor
        # for each actor
          # calculate their state

    # compare states of each user between windows and map to relevant transition
    PMF.transition(params[:transition_number], params[:start_date], params[:end_date], params[:window])
  end
end
