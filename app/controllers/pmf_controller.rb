class PmfController < ApplicationController
  def states
    parse_pmf_params

    json = Rails.cache.fetch("pmf-states-#{pmf_url_param_string}") do
      Pmf.states_summary(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_pmf_params

    json = Rails.cache.fetch("pmf-state-#{state_name}-#{pmf_url_param_string}") do
      Pmf.state(state_name, @start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end

  def transitions
    parse_pmf_params

    json = Rails.cache.fetch("pmf-transitions-#{pmf_url_param_string}-v2") do
      Pmf.transitions(@start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_pmf_params

    json = Rails.cache.fetch("pmf-transition-#{transition_name}-#{pmf_url_param_string}-v2") do
      Pmf.transition(transition_name, @start_date, @end_date, @window, @threshold, @dependency_threshold).to_json
    end

    render json: json
  end
end
