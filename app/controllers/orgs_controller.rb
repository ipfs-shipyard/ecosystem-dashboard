class OrgsController < ApplicationController
  def protocol
    scope = Issue.all

    if params[:range].present?
      scope = scope.where('created_at > ?', params[:range].to_i.days.ago)
    end

    @orgs =Issue::PROTOCOL_ORGS.map do |org|
      {
        name: org,
        issues_count: scope.issues.org(org).count,
        open_issues_count: scope.issues.org(org).state('open').count,
        closed_issues_count: scope.issues.org(org).state('closed').count,
        pull_requests_count: scope.pull_requests.org(org).count,
        open_pull_requests_count: scope.pull_requests.org(org).state('open').count,
        closed_pull_requests_count: scope.pull_requests.org(org).state('closed').count,
        comments: scope.org(org).sum(:comments_count),
        contributors: scope.org(org).humans.employees.group(:user).count.sort_by(&:last).reverse,
        community_contributors: scope.org(org).not_employees.group(:user).count.sort_by(&:last).reverse,
        bots: scope.org(org).bots.group(:user).count.sort_by(&:last).reverse,
        repos: scope.org(org).group(:repo_full_name).count.sort_by(&:last).reverse
      }
    end
  end
end
