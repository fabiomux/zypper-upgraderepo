# frozen_string_literal: true

require "optparse"
require "zypper/upgraderepo"
require "zypper/upgraderepo/version"

module Zypper
  module Upgraderepo
    CliOptions = Struct.new(
      :operation, :backup_path, :only_enabled, :alias, :name, :hint,
      :overrides, :version, :sorting_by, :view, :only_repo, :timeout,
      :exit_on_fail, :overrides_filename, :only_invalid, :only_protocols,
      :allow_unstable, :only_used
    )

    #
    # Parsing the input data.
    #
    class OptParseMain
      def self.parse(args)
        options = CliOptions.new
        options.operation = :check_current
        options.backup_path = Dir.home
        options.only_enabled = false
        options.alias = true
        options.name = true
        options.hint = true
        options.overrides = {}
        options.version = nil
        options.sorting_by = :alias
        options.view = :table
        options.only_repo = nil
        options.timeout = 10.0
        options.exit_on_fail = false
        options.overrides_filename = nil
        options.only_invalid = false
        options.only_protocols = nil
        options.allow_unstable = false
        options.only_used = nil

        opt_parser = OptionParser.new do |opt|
          opt.banner = if ENV["ZYPPER_UPGRADEREPO"]
                         "Usage: zypper upgraderepo [OPTIONS] [OPERATION]"
                       else
                         "Usage: upgraderepo [OPTIONS] [OPERATION]"
                       end

          opt.separator ""
          opt.separator "Operations:"

          opt.on("-b", "--backup <PATH>", "Create a Tar backup of all the repositories under PATH") do |o|
            options.operation = :backup
            options.only_enabled = false
            options.backup_path = o
          end

          opt.on("-c", "--check-current", "Check the repositories for the current version (Default)") do |_o|
            options.operation = :check_current
          end

          opt.on("-n", "--check-next", "Check the repositories for the next version") do |_o|
            options.operation = :check_next
          end

          opt.on("-C", "--check-for <VERSION>", "Check for a custom VERSION") do |v|
            options.version = v
            options.operation = :check_for
          end

          opt.on("-l", "--check-last", "Check the repositories for the last version") do |_o|
            options.operation = :check_last
          end

          opt.on("-R", "--reset", "Reset the repositories to the current OS version.") do |_v|
            options.operation = :reset
          end

          opt.on("-t", "--update", "Update the repositories to the current OS version") do |_v|
            options.operation = :update
          end

          opt.on("-u", "--upgrade", "Upgrade to the next version available") do |_o|
            options.operation = :upgrade_to_next
          end

          opt.on("-U", "--upgrade-to <VERSION>", "Upgrade to a specific VERSION") do |v|
            options.version = v
            options.operation = :upgrade_to
          end

          opt.on("-L", "--upgrade-to-last", "Upgrade to the last version available") do |_o|
            options.operation = :upgrade_to_last
          end

          opt.on("-s", "--status", "Prints the version status of the current and available releases") do |_o|
            options.operation = :status
          end

          opt.on("-d", "--duplicates", "Detect the duplicates comparing the URL addresses") do |_o|
            options.operation = :duplicates
          end

          opt.on("-z", "--unused", "Prints the unused repositories with zero packages installed") do |_o|
            options.operation = :unused
          end

          opt.separator ""
          opt.separator "Options:"

          opt.on("--allow-unstable", "Consider the unstable version as a valid release version") do |_o|
            options.allow_unstable = true
          end

          opt.on("--no-name", "Don't upgrade the name") do |_o|
            options.name = false
          end

          opt.on("--no-alias", "Don't upgrade the alias") do |_o|
            options.alias = false
          end

          opt.on("--no-hint", "Don't find a working URL when the current is not valid") do |_o|
            options.hint = false
          end

          opt.on("--override-url <NUMBER>,<URL>", Array, "Overwrite the repository NUMBER with URL") do |r|
            options.overrides[r[0].to_i] = r[1]
          end

          opt.on("--load-overrides <FILENAME>", "Load the repositories' overrides from FILENAME") do |f|
            options.overrides_filename = f
          end

          opt.on("--exit-on-fail", "Exit with error when a repository upgrade check fails") do |_o|
            options.exit_on_fail = true
          end

          opt.on("--timeout <SECONDS>",
                 "Adjust the waiting SECONDS used to catch an HTTP Timeout Error (Default: #{options.timeout})") do |o|
            options.timeout = o.to_f
          end

          opt.separator ""
          opt.separator "Filter options:"

          opt.on("--only-enabled", "Include only the enabled repositories") do |_o|
            options.only_enabled = true
          end

          opt.on("--only-repo <NUMBER|NAME|@ALIAS|#URL|&ANY>[,NUMBER2|NAME2|@ALIAS2|#URL2|&ANY2,...]",
                 "Include only the repositories specified by a NUMBER or a string matching the NAME, " \
                 "@ALIAS, #URL, or ?ANY of them") do |o|
            options.only_repo = o.split(",")
          end

          opt.on("--only-invalid", "Show only invalid repositories") do |_o|
            options.only_invalid = true
          end

          opt.on("--only-protocols <PROTOCOL>[,<PROTOCOL2>,...]", Array,
                 "Show only from protocols (supported: #{Request.protocols.join(",")})") do |o|
            options.only_protocols = o
          end

          opt.on("--only-used", "Show only used repositories") do |_o|
            options.only_used = true
          end

          opt.separator ""
          opt.separator "View options:"

          opt.on("--sort-by-alias", "Sort the repositories by alias (Default)") do |_o|
            options.sorting_by = :alias
          end

          opt.on("--sort-by-name", "Sort the repositories by name") do |_o|
            options.sorting_by = :name
          end

          opt.on("--sort-by-priority", "Sort the repositories by priority") do |_o|
            options.sorting_by = :priority
          end

          opt.on("--ini", "Output the result in the INI format") do |_o|
            options.view = :ini
          end

          opt.on("--quiet", "Quiet mode, show only error messages") do |_o|
            options.view = :quiet
          end

          opt.on("--report", "View the data as a report") do |_o|
            options.view = :report
          end

          opt.on("--solved", "Output as INI and the URLs' suggestions applied") do |_o|
            options.view = :solved
          end

          unless ENV["ZYPPER_UPGRADEREPO"]
            opt.separator ""
            opt.separator "Other:"

            opt.on_tail("-h", "--help", "Show this message") do |_o|
              puts opt
              exit
            end

            opt.on_tail("-v", "--version", "Show the version") do |_o|
              puts VERSION
              exit
            end
          end
        end

        if args.empty?
          puts opt_parser
          exit
        else
          opt_parser.parse!(args)
        end

        options
      end
    end

    #
    # Interface class to run the application.
    #
    class CLI
      def self.start
        options = OptParseMain.parse(ARGV)
        Upgraderepo::Builder.new(options).send(options.operation)
      rescue StandardError => e
        Messages.error e
        exit e.error_code
      end
    end
  end
end
