module DependencyMiner
  def mine_dependencies
    return if fork?

    tmp_dir_name = "github-#{full_name}".downcase

    tmp_path = Rails.root.join("tmp/#{tmp_dir_name}")

    # delete dir if already exists
    `rm -rf #{tmp_path}`

    # download code
    system "GIT_TERMINAL_PROMPT=0 git clone -b #{default_branch} --single-branch #{html_url} #{tmp_path}"

    return unless tmp_path.exist? # handle failed clones

    # mine dependency activity from git repository
    miner = RepoMiner::Repository.new(tmp_path.to_s)

    # Find last commit analysed
    last_commit_sha = dependency_events.order('committed_at DESC').first.try(:commit_sha)

    # store activities as DependencyActivity records
    commits = miner.analyse(default_branch, last_commit_sha)

    # only consider commits with dependency data
    dependency_commits = commits.select{|c| c.data[:dependencies].present? }

    activities = []
    if dependency_commits.any?
      dependency_commits.each do |commit|
        dependency_data = commit.data[:dependencies]

        dependency_data[:added_manifests].each do |added_manifest|
          added_manifest[:added_dependencies].each do |added_dependency|
            activities << format_activity(commit, added_manifest, added_dependency, 'added')
          end
        end

        dependency_data[:modified_manifests].each do |modified_manifest|
          modified_manifest[:added_dependencies].each do |added_dependency|
            activities << format_activity(commit, modified_manifest, added_dependency, 'added')
          end

          modified_manifest[:modified_dependencies].each do |modified_dependency|
            activities << format_activity(commit, modified_manifest, modified_dependency, 'modified')
          end

          modified_manifest[:removed_dependencies].each do |removed_dependency|
            activities << format_activity(commit, modified_manifest, removed_dependency, 'removed')
          end
        end

        dependency_data[:removed_manifests].each do |removed_manifest|
          removed_manifest[:removed_dependencies].each do |removed_dependency|
            activities << format_activity(commit, removed_manifest, removed_dependency, 'removed')
          end
        end
      end
    end

    # write activities to the database
    DependencyEvent.insert_all(activities) if activities.any?
  ensure
    # delete code
    `rm -rf #{tmp_path}`
  end

  def find_package_id(package_name, platform)
    package_id = Package.platform(platform).where(name: package_name.try(:strip)).limit(1).pluck(:id).first
    return package_id if package_id
    Package.lower_platform(platform).lower_name(package_name.try(:strip)).limit(1).pluck(:id).first
  end

  def format_activity(commit, manifest, dependency, action)
    {
      repository_id: id,
      package_id: find_package_id(dependency[:name], manifest[:platform]),
      action: action,
      package_name: dependency[:name],
      commit_message: commit.message,
      requirement: dependency[:requirement],
      kind: dependency[:type],
      manifest_path: manifest[:path],
      manifest_kind: manifest[:kind],
      commit_sha: commit.sha,
      platform: manifest[:platform],
      previous_requirement: dependency[:previous_requirement],
      previous_kind: dependency[:previous_type],
      committed_at: commit.timestamp,
      branch: default_branch
    }
  end
end
