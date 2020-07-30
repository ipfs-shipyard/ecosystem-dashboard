# frozen_string_literal: true

module PackageManager
  class Rubygems < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://rubygems.org"
    COLOR = "#701516"
    GITHUB_PACKAGE_SUPPORT = true

    def self.package_link(package, version = nil)
      "https://rubygems.org/gems/#{package.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.download_url(name, version = nil)
      "https://rubygems.org/downloads/#{name}-#{version}.gem"
    end

    def self.documentation_url(name, version = nil)
      "http://www.rubydoc.info/gems/#{name}/#{version}"
    end

    def self.install_instructions(package, version = nil)
      "gem install #{package.name}" + (version ? " -v #{version}" : "")
    end

    def self.check_status_url(package)
      "https://rubygems.org/api/v1/versions/#{package.name}.json"
    end

    def self.package_names
      gems = Marshal.safe_load(Gem.gunzip(get_raw("http://production.cf.rubygems.org/specs.4.8.gz")))
      gems.map(&:first).uniq
    end

    def self.recent_names
      updated = get("https://rubygems.org/api/v1/activity/just_updated.json").map { |h| h["name"] }
      new_gems = get("https://rubygems.org/api/v1/activity/latest.json").map { |h| h["name"] }
      (updated + new_gems).uniq
    end

    def self.package(name)
      get_json("https://rubygems.org/api/v1/gems/#{name}.json")
    rescue StandardError
      {}
    end

    def self.mapping(package)
      {
        name: package["name"],
        description: package["info"],
        homepage: package["homepage_uri"],
        licenses: package.fetch("licenses", []).try(:join, ","),
        repository_url: repo_fallback(package["source_code_uri"], package["homepage_uri"]),
      }
    end

    def self.versions(package, _name)
      json = get_json("https://rubygems.org/api/v1/versions/#{package['name']}.json")
      json.map do |v|
        {
          number: v["number"],
          published_at: v["created_at"],
          original_license: v.fetch("licenses"),
        }
      end
    rescue StandardError
      []
    end

    def self.dependencies(name, version, _package)
      json = get_json("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")

      deps = json["dependencies"]
      map_dependencies(deps["development"], "Development") + map_dependencies(deps["runtime"], "runtime")
    rescue StandardError
      []
    end

    def self.map_dependencies(deps, kind)
      deps.map do |dep|
        {
          package_name: dep["name"],
          requirements: dep["requirements"],
          kind: kind,
          platform: name.demodulize,
        }
      end
    end

    def self.download_registry_users(name)
      json = get_json("https://rubygems.org/api/v1/gems/#{name}/owners.json")
      json.map do |user|
        {
          uuid: user["id"],
          email: user["email"],
          login: user["handle"],
        }
      end
    rescue StandardError
      []
    end

    def self.registry_user_url(login)
      "https://rubygems.org/profiles/#{login}"
    end
  end
end
