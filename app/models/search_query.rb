class SearchQuery < ApplicationRecord
  validates_presence_of :query, :kind, :sort, :order
  validates :kind, inclusion: { in: ["commits", "code", "issues", "repositories"] }

  has_many :search_results

  def self.bootstrap(query)
    find_or_create_by(kind: 'commits', query: query, sort: 'committer-date', order: 'desc')
    find_or_create_by(kind: 'repositories', query: query, sort: 'updated', order: 'desc')
    find_or_create_by(kind: 'issues', query: query, sort: 'created', order: 'desc')
    find_or_create_by(kind: 'code', query: query, sort: 'indexed', order: 'desc')
    find_or_create_by(kind: 'code', query: "#{query} filename:docker-compose.yml", sort: 'indexed', order: 'desc')
    find_or_create_by(kind: 'code', query: "#{query} filename:dockerfile", sort: 'indexed', order: 'desc')
    find_or_create_by(kind: 'code', query: "#{query} filename:go.mod", sort: 'indexed', order: 'desc')
    find_or_create_by(kind: 'code', query: "#{query} filename:package.json", sort: 'indexed', order: 'desc')
    find_or_create_by(kind: 'code', query: "#{query} filename:cargo.toml", sort: 'indexed', order: 'desc')
  end

  def self.run_all
    all.each(&:run)
  end

  def run
    save_results(fetch.items)
  end

  def fetch
    github_client.send(:search, "search/#{kind}", query,
                                          per_page: 100,
                                          sort: sort,
                                          order: order,
                                          accept: 'application/vnd.github.cloak-preview+json,application/vnd.github.v3.text-match+json')
  end

  def group_and_filter(query_results)
    internal_org_names = Organization.internal.pluck(:name)
    results = query_results.select do |result|
      repository_full_name = case kind
      when 'repositories'
        result.full_name
      when 'issues'
        result.repository_url.gsub('https://api.github.com/repos/', '')
      else
        result.repository.full_name
      end
      org = repository_full_name.split('/').first
      # exclude internal orgs
      !internal_org_names.include?(org)
    end
    if ['code', 'commits'].include?(kind)
      # Only return one code/commit result per repo
      results = results.group_by{|r| r.repository.full_name }.map{|k,v| v.first}
    end
    results
  end

  def save_results(query_results)
    group_and_filter(query_results).each do |result|
      search_result = SearchResult.find_or_initialize_by(html_url: result.html_url)
      if search_result.new_record?
        search_result.search_query = self
        search_result.kind = kind
        search_result.repository_full_name = case kind
        when 'repositories'
          result.full_name
        when 'issues'
          result.repository_url.gsub('https://api.github.com/repos/', '')
        else
          result.repository.full_name
        end
        search_result.title = case kind
        when 'repositories'
          result.full_name
        when 'issues'
          result.title
        when 'code'
          result.path
        when 'commits'
          result.commit.message
        end
        search_result.org = search_result.repository_full_name.split('/').first
        search_result.text_matches = result.text_matches.map(&:to_h)
        search_result.save!
      end
    end
  end

  def github_client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end

  def html_url
    "https://github.com/search?q=#{query}&type=#{kind}&s=#{sort}&o=#{order}"
  end
end
