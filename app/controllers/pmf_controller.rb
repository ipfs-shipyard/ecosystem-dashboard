class PmfController < ApplicationController
  def state
    state_name = params[:state_name]
    start_date = params[:start_date] || 4.weeks.ago
    end_date = params[:end_date] || Time.now
    window = params[:window] || 1

    render json: Pmf.state(state_name, start_date, end_date, window).to_json
  end

  def transition
    transition_number = params[:transition_number]
    start_date = params[:start_date] || 4.weeks.ago
    end_date = params[:end_date] || Time.now
    window = params[:window] || 1

    Pmf.transition(transition_number, start_date, end_date, window).to_json
  end
end
