class PmfRepoController < ApplicationController
  def states
    parse_pmf_params

    json = PmfRepo.states_summary(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json

    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_pmf_params

    json = PmfRepo.state(state_name, @start_date, @end_date, @window, @threshold, @dependency_threshold).to_json

    render json: json
  end

  def transitions
    parse_pmf_params

    json = PmfRepo.transitions(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_pmf_params

    json = PmfRepo.transition(transition_name, @start_date, @end_date, @window, @threshold, @dependency_threshold).to_json

    render json: json
  end

  private

  def parse_pmf_params
    @start_date = params[:start_date].presence || Time.now.yesterday.end_of_day - 4.weeks
    @threshold = params[:threshold].presence || nil
    @dependency_threshold = params[:dependency_threshold].presence || 0

    if params[:window] =~ /\A[-+]?[0-9]+\z/ # integer
      @end_date = params[:end_date].presence || Time.now.yesterday.end_of_day
      @window = params[:window].to_i.days
    else
      @end_date = params[:end_date].presence || Time.now.last_week.at_end_of_week
      if params[:window] == 'month'
        @window = 'month'
      elsif params[:window] == 'week'
        @window = 'week'
      else
        @window = 14
      end
    end
  end
end
