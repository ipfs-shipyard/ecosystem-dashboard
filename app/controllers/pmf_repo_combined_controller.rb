class PmfRepoCombinedController < ApplicationController
  def states
    parse_pmf_params

    json = Rails.cache.fetch("combined-states-#{pmf_url_param_string}") do
      result = load_and_combine_states

      result = result.map do |window|
        {date: window[:date], states: Hash[window[:states].map{|k,v| [k,v.length]}]}
      end
      result.to_json
    end

    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_pmf_params

    json = Rails.cache.fetch("combined-state-#{state_name}-#{pmf_url_param_string}") do
      result = load_and_combine_states

      result = result.map do |window|
        {date: window[:date], states: Hash[window[:states].select{|k,v| k.to_s == state_name }]}
      end
      result.to_json
    end

    render json: json
  end

  def transitions
    parse_pmf_params

    json = Rails.cache.fetch("combined-transitions-#{pmf_url_param_string}") do
      result = load_and_combine_transitions

      result = result.map do |window|
        {date: window[:date], transitions: Hash[window[:transitions].map{|k,v| [k,v.length]}]}
      end
      result.to_json
    end

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_pmf_params

    json = Rails.cache.fetch("combined-transition-#{transition_name}-#{pmf_url_param_string}") do
      result = load_and_combine_transitions

      result = result.map do |window|
        {date: window[:date], transitions: Hash[window[:transitions].select{|k,v| k.to_s == transition_name }]}
      end

      result.to_json
    end

    render json: json
  end

  def repo_transitions
    parse_pmf_params

    json = Rails.cache.fetch("combined-repo_transitions-#{pmf_url_param_string}") do
      load_and_combine_transitions.to_json
    end

    render json: json
  end

  def repo_states
    parse_pmf_params

    json = Rails.cache.fetch("combined-repo_transitions-#{pmf_url_param_string}") do
      load_and_combine_states.to_json
    end

    render json: json
  end

  private

  def load_and_combine_states
    # load ipfs states
    ipfs_result = PmfRepo.states(@start_date, @end_date, @window, @threshold, @dependency_threshold)

    # load filecoin states
    res = Faraday.get("#{fil_domain}/repositories/states.json?#{pmf_url_param_string}")
    filecoin_result = Oj.load(res.body)

    # combine
    result = []

    filecoin_result.each do |data|
      states = ipfs_result.find{|h| h[:date].to_s == data['date']}[:states]
      new_states = {}
      states.each do |k,v|
        new_states[k] = ((v || []) + (data['states'][k.to_s] || [])).sort_by{|h| -h.with_indifferent_access[:score] }.uniq{|h| h.with_indifferent_access[:repo_name] }
      end

      result << {date: data['date'], states: new_states}
    end

    result
  end

  def load_and_combine_transitions
    # load ipfs states
    ipfs_result = PmfRepo.transitions_with_details(@start_date, @end_date, @window, @threshold, @dependency_threshold)

    # load filecoin states
    res = Faraday.get("#{fil_domain}/repositories/transitions.json?#{pmf_url_param_string}")
    filecoin_result = Oj.load(res.body)

    # combine
    result = []

    filecoin_result.each do |data|
      transitions = ipfs_result.find{|h| h[:date].to_s == data['date']}[:transitions]
      new_transitions = {}
      transitions.each do |k,v|
        new_transitions[k] = ((v || []) + (data['transitions'][k.to_s] || [])).sort_by{|h| -h.with_indifferent_access[:score] }.uniq{|h| h.with_indifferent_access[:repo_name] }
      end

      result << {date: data['date'], transitions: new_transitions}
    end

    result
  end

  def fil_domain
    "https://filecoin.ecosystem-dashboard.com"
  end
end
