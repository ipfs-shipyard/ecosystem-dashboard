class PmfController < ApplicationController
  def states
    parse_date_params

    json = Pmf.states_summary(@start_date, @end_date, @window).to_json

    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_date_params

    json = Pmf.state(state_name, @start_date, @end_date, @window).to_json

    render json: json
  end

  def transitions
    parse_date_params

    json = Pmf.transitions(@start_date, @end_date, @window).to_json

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_date_params

    json = Pmf.transition(transition_name, @start_date, @end_date, @window).to_json

    render json: json
  end

  private

  def parse_date_params
    @start_date = params[:start_date].presence || 4.weeks.ago.beginning_of_week
    @end_date = params[:end_date].presence || Time.now.beginning_of_week

    case params[:window]
    when 'month'
      @window = 1.month
    else
      @window = 1.week
    end
  end
end
