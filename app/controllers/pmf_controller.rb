class PmfController < ApplicationController
  def states
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    json = Rails.cache.fetch([start_date, end_date, window], expires_in: 12.hours) do
      Pmf.states_summary(start_date, end_date, window).to_json
    end

    render json: json
  end

  def state
    state_name = params[:state_name]
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    json = Rails.cache.fetch([state_name, start_date, end_date, window], expires_in: 12.hours) do
      Pmf.state(state_name, start_date, end_date, window).to_json
    end

    render json: json
  end

  def transitions
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    json = Rails.cache.fetch([start_date, end_date, window], expires_in: 12.hours) do
      Pmf.transitions(start_date, end_date, window).to_json
    end

    render json: json
  end

  def transition
    transition_name = params[:transition_name]
    start_date = params[:start_date] || 4.weeks.ago.beginning_of_week
    end_date = params[:end_date] || Time.now.beginning_of_week
    window = params[:window] || 1

    json = Rails.cache.fetch([transition_name, start_date, end_date, window], expires_in: 12.hours) do
      Pmf.transition(transition_name, start_date, end_date, window).to_json
    end

    render json: json
  end
end
