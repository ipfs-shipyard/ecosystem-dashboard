# frozen_string_literal: true

module PackageManager
  class Cargo < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://crates.io"
    COLOR = "#dea584"

    def self.package_link(package, version = nil)
      "https://crates.io/crates/#{package.name}/#{version}"
    end

    def self.download_url(name, version = nil)
      "https://crates.io/api/v1/crates/#{name}/#{version}/download"
    end

    def self.documentation_url(name, version = nil)
      "https://docs.rs/#{name}/#{version}"
    end

    def self.check_status_url(package)
      "https://crates.io/api/v1/crates/#{package.name}"
    end

    def self.package_names
      page = 1
      packages = []
      loop do
        r = get("https://crates.io/api/v1/crates?page=#{page}&per_page=100")["crates"]
        break if r == []

        packages += r
        page += 1
      end
      packages.map { |package| package["name"] }
    end

    def self.recent_names
      json = get("https://crates.io/api/v1/summary")
      updated_names = json["just_updated"].map { |c| c["name"] }
      new_names = json["new_crates"].map { |c| c["name"] }
      (updated_names + new_names).uniq
    end

    def self.package(name)
      get("https://crates.io/api/v1/crates/#{name}")
    end

    def self.mapping(package)
      return false unless package["versions"].present?
      latest_version = package["versions"].to_a.first
      {
        name: package["crate"]["id"],
        homepage: package["crate"]["homepage"],
        description: package["crate"]["description"],
        keywords_array: Array.wrap(package["crate"]["keywords"]),
        licenses: latest_version["license"],
        repository_url: repo_fallback(package["crate"]["repository"], package["crate"]["homepage"]),
      }
    end

    def self.versions(package, _name)
      package["versions"].map do |version|
        {
          number: version["num"],
          published_at: version["created_at"],
        }
      end
    end

    def self.dependencies(name, version, _package)
      deps = get("https://crates.io/api/v1/crates/#{name}/#{version}/dependencies")["dependencies"]
      return [] if deps.nil?

      deps.map do |dep|
        {
          package_name: dep["crate_id"],
          requirements: dep["req"],
          kind: dep["kind"],
          optional: dep["optional"],
          platform: self.name.demodulize,
        }
      end
    end

    def self.download_registry_users(name)
      json = get_json("https://crates.io/api/v1/crates/#{name}/owner_user")
      json["users"].map do |user|
        {
          uuid: user["id"],
          name: user["name"],
          login: user["login"],
          url: user["url"],
        }
      end
    rescue StandardError
      []
    end

    def self.registry_user_url(login)
      "https://crates.io/users/#{login}"
    end

    def self.dependents(name)
      page = 1
      packages = []
      loop do
        r = get("https://crates.io/api/v1/crates/#{name}/reverse_dependencies?page=#{page}&per_page=100")["versions"]
        break if r == []

        packages += r
        page += 1
      end
      packages.map { |package| package["crate"] }
    end
  end
end
