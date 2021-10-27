module DependencyMiner
  def mine_dependencies
    return if fork?
    return if size > 100_000

    @package_cache = {}
    Package.internal_or_partner.select(:id, :name, :platform).each do |pkg|
      @package_cache["#{pkg.platform.downcase}-#{pkg.name}"] = pkg.id
    end

    tmp_dir_name = "github-#{full_name}".downcase

    tmp_path = Rails.root.join("tmp/#{tmp_dir_name}")

    # delete dir if already exists
    `rm -rf #{tmp_path}`

    # download code
    system "GIT_TERMINAL_PROMPT=0 git clone -b #{default_branch} --single-branch #{html_url} #{tmp_path}"

    return unless tmp_path.exist? # handle failed clones

    matches = ENV['KEYWORDS'].to_s.split(',').map do |keyword|
      `cd #{tmp_path} && git grep --line-number #{keyword}`
    end

    combined_matches = matches.join("\n").strip

    if combined_matches.present?
      update_column(:keyword_matches, combined_matches)
    else
      update_column(:keyword_matches, nil)
    end

    # mine dependency activity from git repository
    miner = RepoMiner::Repository.new(tmp_path.to_s)

    miner.walk(default_branch, latest_commit_sha).each do |commit|
      begin
        latest_commit_sha = commit.oid
        rc = RepoMiner::Commit.new(miner, commit).analyse
        next unless rc.data[:dependencies].present?

        activities = []

        dependency_data = rc.data[:dependencies]

        dependency_data[:added_manifests].each do |added_manifest|
          added_manifest[:added_dependencies].each do |added_dependency|
            activities << format_activity(rc, added_manifest, added_dependency, 'added')
          end
        end

        dependency_data[:modified_manifests].each do |modified_manifest|
          modified_manifest[:added_dependencies].each do |added_dependency|
            activities << format_activity(rc, modified_manifest, added_dependency, 'added')
          end

          modified_manifest[:modified_dependencies].each do |modified_dependency|
            activities << format_activity(rc, modified_manifest, modified_dependency, 'modified')
          end

          modified_manifest[:removed_dependencies].each do |removed_dependency|
            activities << format_activity(rc, modified_manifest, removed_dependency, 'removed')
          end
        end

        dependency_data[:removed_manifests].each do |removed_manifest|
          removed_manifest[:removed_dependencies].each do |removed_dependency|
            activities << format_activity(rc, removed_manifest, removed_dependency, 'removed')
          end
        end

        if activities.any?
          activities = activities.compact.uniq

          # write activities to the database
          DependencyEvent.insert_all(activities)

          update({latest_commit_sha: latest_commit_sha, latest_dependency_mine: Time.now})
        end
      rescue ArgumentError
        # invalid utf8 in path
      end
    end

    update({
      latest_commit_sha: latest_commit_sha,
      latest_dependency_mine: Time.now,
      first_added_internal_deps: calculate_first_added_internal_deps,
      last_internal_dep_removed: calculate_last_internal_dep_removed
    })
  rescue Rugged::OdbError
    update({latest_commit_sha: nil})
  ensure
    # delete code
    `rm -rf #{tmp_path}`
  end

  def calculate_first_added_internal_deps
    dependency_events.order('committed_at ASC').action('added').first.try(:committed_at)
  end

  def calculate_last_internal_dep_removed
    if dependency_events.action('added').count == dependency_events.action('removed').count
      dependency_events.order('committed_at ASC').action('removed').last.try(:committed_at)
    end
  end

  def format_activity(commit, manifest, dependency, action)
    return nil unless @package_cache["#{manifest[:platform]}-#{dependency[:name]}"]
    {
      repository_id: id,
      package_id: @package_cache["#{manifest[:platform]}-#{dependency[:name]}"],
      action: action,
      package_name: dependency[:name],
      commit_message: commit.message.force_encoding('UTF-8'),
      requirement: dependency[:requirement],
      kind: dependency[:type],
      manifest_path: manifest[:path].force_encoding('UTF-8'),
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
