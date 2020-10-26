class ApplicationController < ActionController::Base
  include Pagy::Backend
  after_action { pagy_headers_merge(@pagy) if @pagy }

  def authenticate_user!
    return if logged_in?
    respond_to do |format|
      format.html { redirect_to root_path, flash: {error: 'Unauthorized access, please log in first'} }
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
end
