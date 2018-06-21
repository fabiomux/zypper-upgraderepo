
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "zypper/upgraderepo/version"

Gem::Specification.new do |spec|
  spec.name          = "zypper-upgraderepo"
  spec.version       = Zypper::Upgraderepo::VERSION
  spec.authors       = ["Fabio Mucciante"]
  spec.email         = ["fabio.mucciante@gmail.com"]

  spec.summary       = %q{Zypper addon to check and upgrade local repositories.}
  spec.description   = %q{This is just a complement to zypper command which helps to upgrade the local repositories before executing zypper dup.}
  spec.homepage      = "https://github.com/fabiomux/zypper-upgraderepo"
  spec.license       = "GPL v.3"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "iniparse"
  spec.add_runtime_dependency "minitar"
end
