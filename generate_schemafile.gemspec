
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "generate_schemafile/version"

Gem::Specification.new do |spec|
  spec.name          = "generate_schemafile"
  spec.version       = GenerateSchemafile::VERSION
  spec.authors       = ["yoshitsugu_fujii"]
  spec.email         = ["4429.fujii@gmail.com"]

  spec.summary       = %q{Create a ridgepole SCHEMAFILE from Excel}
  spec.description   = %q{Create a ridgepole SCHEMAFILE from Excel}
  spec.homepage      = "https://github.com/YoshitsuguFujii"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"

  spec.add_dependency "rubyXL"
  spec.add_dependency "axlsx"
end
