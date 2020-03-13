class OrgsController < ApplicationController
  def protocol
    @orgs =Issue::PROTOCOL_ORGS.map do |org|
      {
        name: org,
        issues_count: Issue.issues.org(org).count,
        open_issues_count: Issue.issues.org(org).state('open').count,
        closed_issues_count: Issue.issues.org(org).state('closed').count,
        pull_requests_count: Issue.pull_requests.org(org).count,
        open_pull_requests_count: Issue.pull_requests.org(org).state('open').count,
        closed_pull_requests_count: Issue.pull_requests.org(org).state('closed').count,
        comments: Issue.org(org).sum(:comments_count),
        contributors: Issue.org(org).humans.employees.group(:user).count.sort_by(&:last).reverse,
        community_contributors: Issue.org(org).not_employees.group(:user).count.sort_by(&:last).reverse,
        bots: Issue.org(org).bots.group(:user).count.sort_by(&:last).reverse,
        repos: Issue.org(org).group(:repo_full_name).count.sort_by(&:last).reverse
      }
    end
  end
end
