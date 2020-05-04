# frozen_string_literal: true

module PackageManager
  class Hex < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://hex.pm"
    COLOR = "#6e4a7e"

    def self.package_link(package, version = nil)
      "https://hex.pm/packages/#{package.name}/#{version}"
    end

    def self.download_url(name, version = nil)
      "https://repo.hex.pm/tarballs/#{name}-#{version}.tar"
    end

    def self.documentation_url(name, version = nil)
      "http://hexdocs.pm/#{name}/#{version}"
    end

    def self.package_names
      page = 1
      packages = []
      while page < 1000
        r = get("https://hex.pm/api/packages?page=#{page}")
        break if r == []

        packages += r
        page += 1
      end
      packages.map { |package| package["name"] }
    end

    def self.recent_names
      (get("https://hex.pm/api/packages?sort=inserted_at").map { |package| package["name"] } +
      get("https://hex.pm/api/packages?sort=updated_at").map { |package| package["name"] }).uniq
    end

    def self.package(name)
      sleep 30
      get("https://hex.pm/api/packages/#{name}")
    end

    def self.mapping(package)
      links = package["meta"].fetch("links", {}).each_with_object({}) do |(k, v), h|
        h[k.downcase] = v
      end
      {
        name: package["name"],
        homepage: links.except("github").first.try(:last),
        repository_url: links["github"],
        description: package["meta"]["description"],
        licenses: repo_fallback(package["meta"].fetch("licenses", []).join(","), links.except("github").first.try(:last)),
      }
    end

    def self.versions(package, _name)
      package["releases"].map do |version|
        {
          number: version["version"],
          published_at: version["inserted_at"],
        }
      end
    end

    def self.dependencies(name, version, _package)
      deps = get("https://hex.pm/api/packages/#{name}/releases/#{version}")["requirements"]
      return [] if deps.nil?

      deps.map do |k, v|
        {
          package_name: k,
          requirements: v["requirement"],
          kind: "runtime",
          optional: v["optional"],
          platform: self.name.demodulize,
        }
      end
    end

    def self.download_registry_users(name)
      json = get_json("https://hex.pm/api/packages/#{name}")
      json["owners"].map do |user|
        {
          uuid: "hex-" + user["username"],
          email: user["email"],
          login: user["username"],
        }
      end
    rescue StandardError
      []
    end

    def self.registry_user_url(login)
      "https://hex.pm/users/#{login}"
    end
  end
end
