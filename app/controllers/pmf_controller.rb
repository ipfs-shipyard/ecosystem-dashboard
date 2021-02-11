class PmfController < ApplicationController
  def states
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    render json: Pmf.states_summary(start_date, end_date, window).to_json
  end

  def state
    state_name = params[:state_name]
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    render json: Pmf.state(state_name, start_date, end_date, window).to_json
  end

  def transitions
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    render json: Pmf.transitions(start_date, end_date, window).to_json
  end

  def transition
    transition_name = params[:transition_name]
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    render json: Pmf.transition(transition_name, start_date, end_date, window).to_json
  end
end
