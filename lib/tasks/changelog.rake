namespace :changelog do
  task missing: :environment do
    release_events = Event.internal.event_type('ReleaseEvent').includes(:repository)
    repos = release_events.map(&:repository).uniq.reject(&:archived?)
    repos.each do |repo|
      file_list = repo.get_file_list

      changelog = file_list.find{|file| file.match(/^CHANGE|^HISTORY/i) }
      if changelog

      else
        puts repo.full_name
        # pp file_list
      end
    end
  end

  task generate: :environment do
    full_name = 'ipfs-shipyard/ipfs-desktop'
    repo = Repository.find_by_full_name(full_name)
    releases = repo.events.event_type('ReleaseEvent')


    releases.order('created_at desc').each_with_index do |release, index|
      if index.zero?
        puts "# Changelog\nAll notable changes to this project will be documented in this file.\n\nThe format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
      end
      puts "## [#{release.payload['release']['tag_name']}] - #{release.created_at.strftime("%Y-%m-%d")}"
      puts release.payload['release']['body']
    end;nil
  end
end


# This changelog was automatically generated from the releases of this GitHub project and the format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
