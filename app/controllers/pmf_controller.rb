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

  def repositories
    names = params[:names].to_s.split(',').map(&:strip).sort
    @repositories = Repository.where(full_name: names).order('full_name')

    render json: @repositories.to_json(methods: [:direct_internal_dependency_package_names, :indirect_internal_dependency_package_names],
                                       except: [:direct_internal_dependency_package_ids, :indirect_internal_dependency_package_ids])
  end
end
