class SessionsController < ApplicationController
  def new
    if logged_in?
      redirect_to admin_path
    else
      redirect_to '/auth/github'
    end
  end

  def create
    username = authorize_access!
    cookies.permanent.signed[:username] = {value: username, httponly: true}
    redirect_to request.env['omniauth.origin'] || admin_path
  end

  def destroy
    cookies.delete :user_id
    redirect_to root_path
  end

  def failure
    flash[:error] = 'There was a problem authenticating with GitHub, please try again.'
    redirect_to root_path
  end

  private

  def auth_hash
    @auth_hash ||= request.env['omniauth.auth']
  end

  def authorize_access!
    client = Octokit::Client.new(access_token: auth_hash.credentials.token)
    username = auth_hash.info.nickname
    return username if organization_member?(client, user: username)

    flash[:error] = 'Access denied.'
    redirect_to root_path
  end

  def organization_member?(client, user:)
    client.organization_member?(ENV['DEFAULT_ORG'], user, headers: { 'Cache-Control' => 'no-cache, no-store' })
  end
end
