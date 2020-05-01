# frozen_string_literal: true

module PackageManager
  class Pypi < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://pypi.org/"
    COLOR = "#3572A5"

    def self.package_link(package, version = nil)
      "https://pypi.org/package/#{package.name}/#{version}"
    end

    def self.install_instructions(package, version = nil)
      "pip install #{package.name}" + (version ? "==#{version}" : "")
    end

    def self.formatted_name
      "PyPI"
    end

    def self.package_names
      index = Nokogiri::HTML(get_raw("https://pypi.org/simple/"))
      index.css("a").map(&:text)
    end

    def self.recent_names
      u = "https://pypi.org/rss/updates.xml"
      updated = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      u = "https://pypi.org/rss/packages.xml"
      new_packages = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      (updated.map { |t| t.split(" ").first } + new_packages.map { |t| t.split(" ").first }).uniq
    end

    def self.package(name)
      get("https://pypi.org/pypi/#{name}/json")
    rescue StandardError
      {}
    end

    def self.mapping(package)
      {
        name: package["info"]["name"],
        description: package["info"]["summary"],
        homepage: package["info"]["home_page"],
        keywords_array: Array.wrap(package["info"]["keywords"].try(:split, /[\s.,]+/)),
        licenses: licenses(package),
        repository_url: repo_fallback(
          package.dig("info", "package_urls", "Source").presence || package.dig("info", "package_urls", "Source Code"),
          package["info"]["home_page"].presence || package.dig("info", "package_urls", "Homepage")
        ),
      }
    end

    def self.versions(package, name)
      package["releases"].reject { |_k, v| v == [] }.map do |k, v|
        release = get("https://pypi.org/pypi/#{name}/#{k}/json")
        {
          number: k,
          published_at: v[0]["upload_time"],
          original_license: release.dig("info", "license"),
        }
      end
    end

    def self.dependencies(name, version, _package)
      deps = get("http://pip.libraries.io/#{name}/#{version}.json")
      return [] if deps.is_a?(Hash) && deps["error"].present?

      deps.map do |dep|
        {
          package_name: dep["name"],
          requirements: dep["requirements"] || "*",
          kind: "runtime",
          optional: false,
          platform: self.name.demodulize,
        }
      end
    end

    def self.licenses(package)
      return package["info"]["license"] if package["info"]["license"].present?

      license_classifiers = package["info"]["classifiers"].select { |c| c.start_with?("License :: ") }
      license_classifiers.map { |l| l.split(":: ").last }.join(",")
    end

    def self.package_find_names(package_name)
      [
        package_name,
        package_name.gsub("-", "_"),
        package_name.gsub("_", "-"),
      ]
    end
  end
end
