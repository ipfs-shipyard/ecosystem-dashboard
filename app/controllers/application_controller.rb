class ApplicationController < ActionController::Base
  include Pagy::Backend
  after_action { pagy_headers_merge(@pagy) if @pagy }

  def authenticate_user!
    return if logged_in?
    respond_to do |format|
      format.html { redirect_to login_path, flash: {error: 'Unauthorized access, please log in first'} }
      format.json { render json: { "error" => "unauthorized" }, status: :unauthorized }
    end
  end

  helper_method :current_user
  def current_user
    @current_user ||= cookies.permanent.signed[:username]
  end

  helper_method :logged_in?
  def logged_in?
    !current_user.nil?
  end

  def parse_pmf_params
    @start_date = params[:start_date].presence || Time.now.yesterday.end_of_day - 4.weeks
    @end_date = params[:end_date].presence || Time.now.yesterday.end_of_day
    @threshold = params[:threshold].presence || PmfRepo::DEFAULT_THRESHOLD
    @dependency_threshold = params[:dependency_threshold].presence || 1

    if params[:window] =~ /\A[-+]?[0-9]+\z/ # integer
      @window = params[:window].to_i
    else
      if params[:window] == 'month'
        @end_date = params[:end_date].presence || Time.now.last_week.at_end_of_week
        @window = 'month'
      elsif params[:window] == 'week'
        @end_date = params[:end_date].presence || Time.now.last_week.at_end_of_week
        @window = 'week'
      else
        @window = 14
      end
    end
  end

  def pmf_url_param_string
    "start_date=#{@start_date.to_date}&end_date=#{@end_date.to_date}&window=#{@window}&threshold=#{@threshold}&dependency_threshold=#{@dependency_threshold}"
  end
end
