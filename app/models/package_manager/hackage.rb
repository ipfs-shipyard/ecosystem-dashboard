# frozen_string_literal: true

module PackageManager
  class Hackage < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "http://hackage.haskell.org"
    COLOR = "#29b544"

    def self.package_link(package, version = nil)
      "http://hackage.haskell.org/package/#{package.name}" + (version ? "-#{version}" : "")
    end

    def self.download_url(name, version = nil)
      "http://hackage.haskell.org/package/#{name}-#{version}/#{name}-#{version}.tar.gz"
    end

    def self.install_instructions(package, version = nil)
      "cabal install #{package.name}" + (version ? "-#{version}" : "")
    end

    def self.package_names
      get_json("http://hackage.haskell.org/packages/").map { |h| h["packageName"] }
    end

    def self.recent_names
      u = "http://hackage.haskell.org/packages/recent.rss"
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split(" ").first }.uniq
    end

    def self.package(name)
      {
        name: name,
        page: get_html("http://hackage.haskell.org/package/#{name}"),
      }
    end

    def self.mapping(package)
      {
        name: package[:name],
        keywords_array: Array(package[:page].css("#content div:first a")[1..-1].map(&:text)),
        description: description(package[:page]),
        licenses: find_attribute(package[:page], "License"),
        homepage: find_attribute(package[:page], "Home page"),
        repository_url: repo_fallback(repository_url(find_attribute(package[:page], "Source repository")), find_attribute(package[:page], "Home page")),
      }
    end

    def self.versions(package, _name)
      versions = find_attribute(package[:page], "Versions")
      versions = find_attribute(package[:page], "Version") if versions.nil?
      versions.delete("(info)").split(",").map(&:strip).map do |v|
        {
          number: v,
        }
      end
    end

    def self.find_attribute(page, name)
      tr = page.css("#content tr").select { |t| t.css("th").text == name }.first
      tr&.css("td")&.text
    end

    def self.description(page)
      contents = page.css("#content p, #content hr").map(&:text)
      index = contents.index ""
      return "" unless index

      contents[0..(index - 1)].join("\n\n")
    end

    def self.repository_url(text)
      return nil unless text.present?

      match = text.match(/github.com\/(.+?)\.git/)
      return nil unless match

      "https://github.com/#{match[1]}"
    end
  end
end
