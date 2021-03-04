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
end
