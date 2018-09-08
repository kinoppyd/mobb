
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mobb/version"

Gem::Specification.new do |spec|
  spec.name          = "mobb"
  spec.version       = Mobb::VERSION
  spec.authors       = ["kinoppyd"]
  spec.email         = ["WhoIsDissolvedGirl+github@gmail.com"]

  spec.summary       = %q{Mobb is a lightweight Bot framework like Sinatra}
  spec.description   = %q{Mobb provides bot DSL}
  spec.homepage      = "https://github.com/kinoppyd/mobb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "repp", "~> 0.2"
  spec.add_dependency "whenever", "~> 0.10"
  spec.add_dependency "parse-cron", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
