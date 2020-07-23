module PackageManager
  class Go < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://pkg.go.dev/'
    COLOR = '#375eab'
    KNOWN_HOSTS = [
      'bitbucket.org',
      'github.com',
      'launchpad.net',
      'hub.jazz.net',
    ]
    KNOWN_VCS = [
      '.bzr',
      '.fossil',
      '.git',
      '.hg',
      '.svn',
    ]


    def self.package_link(package, version = nil)
      "https://pkg.go.dev/#{project.name}#{"@#{version}" if version}"
    end

    def self.documentation_url(name, version = nil)
      "https://pkg.go.dev/#{name}#{"@#{version}" if version}?tab=doc"
    end

    def self.install_instructions(package, version = nil)
      "go get #{package.name}"
    end

    def self.package_names
      get_raw("https://index.golang.org/index")
    end

    def self.package(name)
      {
        name: name
      }
    end

    def self.mapping(package)
      {
        name: package[:name],
        description: package['Synopsis'],
        repository_url: get_repository_url(package[:name])
      }
    end

    def self.versions(package, _name)
      txt = get_raw("https://proxy.golang.org/#{package[:name]}/@v/list")
      versions = txt.split("\n")

      versions.map do |v|
        {
          number: v,
          published_at: get_version(package[:name], v).fetch('Time')
        }
      end
    rescue StandardError
      []
    end

    def self.dependencies(name, version, _package)
      mod_file = get_raw("https://proxy.golang.org/#{name}/@v/#{version}.mod")

      Bibliothecary::Parsers::Go.parse_go_mod(mod_file).map do |dep|
        {
          package_name: dep[:name],
          requirements: dep[:requirement],
          kind: dep[:type],
          platform: "Go",
        }
      end
    rescue StandardError
      []
    end

    # https://golang.org/cmd/go/#hdr-Import_path_syntax
    def self.package_find_names(name)
      return [name] if name.start_with?(*KNOWN_HOSTS)
      return [name] if KNOWN_VCS.any?(&name.method(:include?))

      go_import = get_html('https://' + name + '?go-get=1')
        .xpath('//meta[@name="go-import"]')
        .first
        &.attribute("content")
        &.value
        &.split(" ")
        &.last
        &.sub(/https?:\/\//, "")

      go_import&.start_with?(*KNOWN_HOSTS) ? [go_import] : [name]
    rescue Faraday::ConnectionFailed, URI::InvalidURIError
      []
    end

    def self.get_repository_url(package_name)
      res = request("https://#{package_name}")
      res.env.url.to_s if res.success?
    end

    def self.get_version(package_name, version)
      get_json("https://proxy.golang.org/#{package_name}/@v/#{version}.info")
    end

    def self.dependents(name)
      url = "https://pkg.go.dev/#{project.name}?tab=importedby"
      page = get_html(url)
      page.css('.Details-indent a').map(&:text)
    end
  end
end
