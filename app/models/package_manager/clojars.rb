# frozen_string_literal: true

module PackageManager
  class Clojars < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://clojars.org"
    COLOR = "#db5855"

    def self.package_link(package, version = nil)
      "https://clojars.org/#{package.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.package_names
      @package_names ||= get("https://clojars.libraries.io/packages.json").keys
    end

    def self.recent_names
      get_html("https://clojars.org/").css(".recent-jar-title a").map(&:text)
    end

    def self.packages
      @packages ||= begin
        projs = {}
        get("https://clojars.libraries.io/feed.json").each do |k, v|
          v.each do |proj|
            group = proj["group-id"]
            key = (group == k ? k : "#{group}/#{k}")
            projs[key] = proj
          end
        end
        projs
      end
    end

    def self.package(name)
      packages[name.downcase].merge(name: name)
    end

    def self.mapping(package)
      {
        name: package[:name],
        description: package["description"],
        repository_url: repo_fallback(package.fetch("scm", {})["url"], ""),
      }
    end

    def self.versions(package, _name)
      package["versions"].map do |v|
        {
          number: v,
        }
      end
    end
  end
end
