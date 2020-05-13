module PackageManager
  class Go < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://godoc.org/'
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
      "http://#{package.name}"
    end

    def self.documentation_url(name, version = nil)
      "http://godoc.org/#{name}"
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
      request("https://#{package_name}").to_hash[:url].to_s
    end

    def self.get_version(package_name, version)
      get_json("https://proxy.golang.org/#{package_name}/@v/#{version}.info")
    end
  end
end
