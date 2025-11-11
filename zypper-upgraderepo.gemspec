# frozen_string_literal: true

require_relative "lib/zypper/upgraderepo/version"

Gem::Specification.new do |spec|
  spec.name = "zypper-upgraderepo"
  spec.version = Zypper::Upgraderepo::VERSION
  spec.authors = ["Fabio Mucciante"]
  spec.email = ["fabio.mucciante@gmail.com"]

  spec.summary = "Zypper addon to check and upgrade local repositories."
  spec.description = "A complement to the zypper CLI tool to upgrade the repositories before executing zypper dup."
  spec.homepage = "https://github.com/fabiomux/zypper-upgraderepo"
  spec.license = "GPL-3.0"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/fabiomux/zypper-upgraderepo",
    "changelog_uri" => "https://freeaptitude.altervista.org/projects/zypper-upgraderepo.html#changelog",
    "wiki_uri" => "https://github.com/fabiomux/zypper-upgraderepo/wiki",
    "rubygems_mfa_required" => "true"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|.github)/|(.gitignore|.travis.yml|CODE_OF_CONDUCT.md)$})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "iniparse"
  spec.add_dependency "minitar"
end
