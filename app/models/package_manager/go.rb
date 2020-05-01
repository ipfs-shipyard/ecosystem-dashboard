module PackageManager
  class Go < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = 'http://go-search.org/'
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
      "http://go-search.org/view?id=#{package.name}"
    end

    def self.documentation_url(name, version = nil)
      "http://godoc.org/#{name}"
    end

    def self.install_instructions(package, version = nil)
      "go get #{package.name}"
    end

    def self.package_names
      get("http://go-search.org/api?action=packages")
    end

    def self.package(name)
      get("http://go-search.org/api?action=package&id=#{name}")
    end

    def self.mapping(package)
      {
        name: package['Package'],
        description: package['Synopsis'],
        homepage: package['PackageURL'],
        repository_url: get_repository_url(package)
      }
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
    end

    def self.get_repository_url(package)
      request("https://#{package['Package']}").to_hash[:url].to_s
    end
  end
end
