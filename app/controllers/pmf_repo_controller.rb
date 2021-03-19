class PmfRepoController < ApplicationController
  def states
    parse_pmf_params

    json = Rails.cache.fetch("pmfrepo-states-#{pmf_url_param_string}") do
      PmfRepo.states_summary(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_pmf_params

    json = Rails.cache.fetch("pmfrepo-state-#{state_name}-#{pmf_url_param_string}") do
      PmfRepo.state(state_name, @start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end

  def transitions
    parse_pmf_params

    json = Rails.cache.fetch("pmfrepo-transitions-#{pmf_url_param_string}-v2") do
      PmfRepo.transitions(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_pmf_params

    json = Rails.cache.fetch("pmfrepo-transition-#{transition_name}-#{pmf_url_param_string}-v2") do
      PmfRepo.transition(transition_name, @start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end
end
