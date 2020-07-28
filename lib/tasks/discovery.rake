namespace :discovery do
  task packages: :environment do
    # find all packages that mention ipfs
    platforms = ['npm', 'maven', 'rubygems', 'pypi', 'cargo', 'packagist', 'nuget', 'clojars', 'cocoapods', 'hackage', 'hex', 'meteor', 'carthage', 'pub']

    platforms.each do |platform|
      puts platform
      results = []
      page = 1
      loop do
        url = "https://libraries.io/api/search?platforms=#{platform}&q=ipfs&per_page=100&page=#{page}"
        json = PackageManager::Base.send :get, url
        break if json.length.zero?
        results += json
        page +=1
        puts page
        sleep 1
      end

      File.open("data/#{platform}-packages.json","w") do |f|
        f.write(results.to_json)
      end
    end
  end

  task package_repos: :environment do
    platforms = ['npm', 'maven', 'rubygems', 'pypi', 'cargo', 'packagist', 'nuget', 'clojars', 'cocoapods', 'hackage', 'hex', 'meteor', 'carthage', 'pub']

    repo_urls = []

    platform = platforms.last

    platforms.each do |platform|
      file = File.open "data/#{platform}-packages.json"
      data = JSON.load file
      repo_urls += data.map{|d| d['repository_url'] }.compact
    end

    File.open("data/package_repos.json","w") do |f|
      f.write(repo_urls.uniq.to_json)
    end
  end

  task package_dependents: :environment do
    platforms = ['npm', 'maven', 'rubygems', 'pypi', 'nuget']

    packages = []

    platforms.each do |platform|
      file = File.open "data/#{platform}-packages.json"
      data = JSON.load file
      valid_packages = data.select{|d| d['repository_url'].present? && d['repository_url'].include?('github') }
      packages += valid_packages
    end
    packages = packages.uniq{|d| d['repository_url'] }.sort_by{|d| d['repository_url'] }

    dependent_repos = []

    packages.each do |package|
      # TODO support repos with multiple packages
      puts package['repository_url']

      url = "#{package['repository_url']}/network/dependents?dependent_type=REPOSITORY"

      while url.present? do
        p url
        begin
          page_contents = PackageManager::Base.send :get_html, url
          names = page_contents.css('#dependents .Box-row .f5.text-gray-light').map{|node| "http://github.com/#{node.text.squish.gsub(' ', '')}" }
          dependent_repos += names
          url = page_contents.css('.paginate-container .btn.btn-outline.BtnGroup-item').select{|n| n.text == 'Next'}.first.try(:attr, 'href')
          sleep 2
        rescue Faraday::ConnectionFailed
          url = nil
        end
      end
    end

    File.open("data/github_package_dependents.json","w") do |f|
      f.write(dependent_repos.uniq.to_json)
    end
  end

  task local_repos: :environment do
    # find collab repos that depend on ipfs packages

  end

  task local_search: :environment do
    # find collab repos that depend on ipfs packages
    search_repo_names = SearchResult.group(:repository_full_name).count.keys
    File.open("data/search_results.json","w") do |f|
      f.write(search_repo_names.to_json)
    end
  end

  task all_repos: :environment do
    search_results = JSON.load(File.open("data/search_results.json")).map{|name| "https://github.com/#{name}"}
    package_repos = JSON.load(File.open("data/package_repos.json"))
    package_dependents = JSON.load(File.open("data/github_package_dependents.json"))

    names = (search_results + package_repos + package_dependents).map(&:downcase).uniq.select{|name| name.include?('github') }
    names.sort.each do |name|
      puts name
    end
    # puts names.length
  end

  task big_orgs: :environment do
    # rows = []
    orgs = {}
    CSV.foreach("data/all_repos.csv") do |row, i|
      # rows << row
      org = row.gsub('https://github.com/', '').split('/').first
      if orgs[org]
        orgs[org] += 1
      else
        orgs[org] = 1
      end
    end

    known_orgs = Organization.all.pluck(:name)
    known_users = Contributor.all.pluck(:github_username)

    pp orgs.reject{|k,v| known_orgs.include?(k) || known_users.include?(k) }.sort_by{|k,v| -v }

    # p rows.length
  end

  task check_status: :environment do
    valid_rows = []
    CSV.foreach("data/all_repos.csv") do |row,i|
      resp = Faraday.head row
      if resp.status == 200
        # p row
        valid_rows << row
      elsif resp.status == 301
        # moved
        valid_rows << resp.headers['location']
        puts "#{row} -> #{resp.headers['location']}"
      elsif resp.status == 404
        puts "#{row} -> DELETED"
        # deleted
      else
        puts "#{row} - #{resp.status}"
      end

      sleep 3
    end

    p valid_rows.sort.uniq

    p valid_rows.length
    p valid_rows.uniq.length
  end

  task ranking: :environment do
    # Is it a fork?                         (fork)
    # Is it archived?                       (archived)
    # How many stars?                       (stargazers_count)
    # How many forks?                       (forks_count)
    # How many watchers?                    (subscribers_count)
    # How long has it existed?              (created_at)
    # When was it last updated?             (updated_at)
    # When was it last committed to?        (pushed_at)
    #
    # Is it owned by an internal org?       (owner)
    # Is it owned by a collab org?          (owner)
    # Is it owned by a collab contributor?  (owner)
    # Is it owned by a core contributor?    (owner)
    #
    # Is it owned by an org?
    # Is it published on a package manager?
    # How many issues?
    # How many pull requests?
    # How many contributors?
    #
    # Does it use go-ipfs as a library?
    # Does it use js-ipfs as a library?
    # Does it use go-ipfs via docker?

  end
end
