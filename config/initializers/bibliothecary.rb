Bibliothecary.configure do |config|
  config.ignored_package_managers = ["bower", "carthage", "clojars", "cocoapods",
    "conda", "cpan", "cran", "dub", "elm", "hackage", "haxelib", "hex", "julia",
    "maven", "meteor", "nuget", "packagist", "pub", "pypi", "rubygems", "shard", "swiftpm"]
end
