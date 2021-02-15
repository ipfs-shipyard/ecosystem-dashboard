class PmfRepoController < ApplicationController
  def states
    parse_date_params

    json = Rails.cache.fetch(['repo_states', @start_date, @end_date, @window], expires_in: 12.hours) do
      PmfRepo.states_summary(@start_date, @end_date, @window).to_json
    end

    render json: json
  end

  def state
    state_name = params[:state_name]
    parse_date_params

    json = Rails.cache.fetch(['repo_state', state_name, @start_date, @end_date, @window], expires_in: 12.hours) do
      PmfRepo.state(state_name, @start_date, @end_date, @window).to_json
    end

    render json: json
  end

  def transitions
    parse_date_params

    json = Rails.cache.fetch(['repo_transitions', @start_date, @end_date, @window], expires_in: 12.hours) do
      PmfRepo.transitions(@start_date, @end_date, @window).to_json
    end

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    parse_date_params

    json = Rails.cache.fetch(['repo_transition', transition_name, @start_date, @end_date, @window], expires_in: 12.hours) do
      PmfRepo.transition(transition_name, @start_date, @end_date, @window).to_json
    end

    render json: json
  end

  private

  def parse_date_params
    @start_date = params[:start_date].presence || 4.weeks.ago.beginning_of_week
    @end_date = params[:end_date].presence || Time.now.beginning_of_week
    @window = params[:window].presence || 1
  end
end
