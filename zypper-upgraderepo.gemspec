
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zypper/upgraderepo/version'

Gem::Specification.new do |spec|
  spec.name          = 'zypper-upgraderepo'
  spec.version       = Zypper::Upgraderepo::VERSION
  spec.authors       = ['Fabio Mucciante']
  spec.email         = ['fabio.mucciante@gmail.com']

  spec.summary       = %q{Zypper addon to check and upgrade local repositories.}
  spec.description   = %q{This is just a complement to zypper command which helps to upgrade the local repositories before executing zypper dup.}
  spec.homepage      = 'https://github.com/fabiomux/zypper-upgraderepo'
  spec.license       = 'GPL-3.0'

  spec.metadata      = {
    "bug_tracker_uri"   => 'https://github.com/fabiomux/zypper-upgraderepo/issues',
    "changelog_uri"     => 'https://freeaptitude.altervista.org/projects/zypper-upgraderepo.html#changelog',
    "documentation_uri" => "https://www.rubydoc.info/gems/zypper-upgraderepo/#{spec.version}",
    "homepage_uri"      => 'https://freeaptitude.altervista.org/projects/zypper-upgraderepo.html',
    #"mailing_list_uri"  => '',
    "source_code_uri"   => 'https://github.com/fabiomux/zypper-upgraderepo',
    "wiki_uri"          => 'https://github.com/fabiomux/zypper-upgraderepo/wiki'
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|.github)/|(.gitignore|.travis.yml|CODE_OF_CONDUCT.md)$})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'iniparse'
  spec.add_runtime_dependency 'minitar'
end
