# frozen_string_literal: true

require "bundler/setup"
require "zypper/upgraderepo"
require "zypper/upgraderepo/cli"

include Zypper::Upgraderepo

#
# Override the variables' calculation.
#
class RepositoryVariablesRSpec < RepositoryVariables
  VAR_CPU_ARCH = "x86_64"
  VAR_ARCH = "x86_64"
end

#
# Override the os-release file.
#
class OsReleaseRspec < OsRelease
  OS_RELEASE_FILE = File.join([Dir.pwd, "spec", "os-release"])
end

#
# Override the repository list.
#
class RepositoryListRspec < RepositoryList
  REPOSITORY_PATH = File.join([Dir.pwd, "spec", "repos"])
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  @options = CliOptions.new

  @options.operation = :check_current
  @options.backup_path = Dir.home
  @options.only_enabled = false
  @options.alias = true
  @options.name = true
  @options.hint = true
  @options.overrides = {}
  @options.version = nil
  @options.sorting_by = :alias
  @options.view = :table
  @options.only_repo = nil
  @options.timeout = 10.0
  @options.exit_on_fail = false
  @options.overrides_filename = nil
  @options.only_invalid = false
  @options.only_protocols = nil
  @options.allow_unstable = false

  @os_release = OsReleaseRspec.new(@options)

  @variables = RepositoryVariablesRSpec.new(@os_release.current)

  config.add_setting :os_release
  config.os_release = @os_release
  config.add_setting :cli_options
  config.cli_options = @options
  config.add_setting :upgraderepo_variables
  config.upgraderepo_variables = @variables
end
