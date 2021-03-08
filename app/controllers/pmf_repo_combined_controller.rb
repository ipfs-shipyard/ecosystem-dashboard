class PmfRepoCombinedController < ApplicationController
  def states
    parse_pmf_params

    result = load_and_combine_states

    result = result.map do |window|
      {date: window[:date], states: Hash[window[:states].map{|k,v| [k,v.length]}]}
    end

    json = result.to_json
    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_pmf_params

    result = load_and_combine_states

    result = result.map do |window|
      {date: window[:date], states: Hash[window[:states].select{|k,v| k == state_name }]}
    end

    json = result.to_json
    render json: json
  end

  def transitions
    parse_pmf_params

    result = load_and_combine_transitions

    result = result.map do |window|
      {date: window[:date], transitions: Hash[window[:transitions].map{|k,v| [k,v.length]}]}
    end

    json = result.to_json
    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_pmf_params

    result = load_and_combine_transitions

    result = result.map do |window|
      {date: window[:date], transitions: Hash[window[:transitions].select{|k,v| k.to_s == transition_name }]}
    end

    json = result.to_json
    render json: json
  end

  def repo_transitions
    parse_pmf_params

    result = load_and_combine_transitions

    json = result.to_json
    render json: json
  end

  def repo_states
    parse_pmf_params

    result = load_and_combine_states

    json = result.to_json
    render json: json
  end

  # TODO repositories/states.json
  # TODO repositories/transitions.json

  private

  def load_and_combine_states
    # load ipfs states
    ipfs_result = PmfRepo.states(@start_date, @end_date, @window, @threshold, @dependency_threshold)

    # load filecoin states
    res = Faraday.get("#{fil_domain}/repositories/states.json?#{url_param_string}")
    filecoin_result = Oj.load(res.body)

    # combine
    result = []

    filecoin_result.each do |data|
      states = ipfs_result.first{|h| h['date'] == data['date']}[:states]
      new_states = {}
      states.each do |k,v|
        new_states[k] = ((v || []) + (data['states'][k] || [])).sort_by{|h| -h.with_indifferent_access[:score] }.uniq{|h| h.with_indifferent_access[:repo_name] }
      end

      result << {date: data['date'], states: new_states}
    end

    result
  end

  def load_and_combine_transitions
    # load ipfs states
    ipfs_result = PmfRepo.transitions_with_details(@start_date, @end_date, @window, @threshold, @dependency_threshold)

    # load filecoin states
    res = Faraday.get("#{fil_domain}/repositories/transitions.json?#{url_param_string}")
    filecoin_result = Oj.load(res.body)

    # combine
    result = []

    filecoin_result.each do |data|
      transitions = ipfs_result.first{|h| h['date'] == data['date']}[:transitions]
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

  def url_param_string
    "start_date=#{@start_date}&end_date=#{@end_date}&window=#{@window}&threshold=#{@threshold}&dependency_threshold=#{@dependency_threshold}"
  end
end
