require 'optparse'
require 'ostruct'
require 'zypper/upgraderepo'
require 'zypper/upgraderepo/version'

module Zypper

  module Upgraderepo

    class OptParseMain

      def self.parse(args)
        options = OpenStruct.new
        options.operation = :check_current
        options.backup_path = ENV['HOME']
        options.only_enabled = false
        options.alias = true
        options.name = true
        options.hint = true
        options.overrides = {}
        options.version = nil
        options.sort_by = :alias
        options.view = :table
        options.list = nil
        options.timeout = 20.0

        opt_parser = OptionParser.new do |opt|

          if ENV['ZYPPER_UPGRADEREPO']
            opt.banner = 'Usage: zypper upgraderepo [OPTIONS] [OPERATION]'
          else
            opt.banner = 'Usage: zypper-upgraderepo [OPTIONS] [OPERATION]'
          end

          opt.separator ''
          opt.separator 'Operations:'

          opt.on('-b', '--backup <PATH>', 'Create a Tar backup of all the repositories under PATH') do |o|
            options.operation = :backup
            options.only_enabled = false
            options.backup_path = o
          end

          opt.on('-c', '--check-current', 'Check the repositories for the current version (Default)') do |o|
            options.operation = :check_current
          end

          opt.on('-N', '--check-next', 'Check the repositories for the next version') do |o|
            options.operation = :check_next
          end

          opt.on('-C', '--check-to <VERSION>', 'Check for a custom VERSION') do |v|
            options.version = v
            options.operation = :check_to
          end

          opt.on('-u', '--upgrade', 'Upgrade to the last version available') do |o|
            options.operation = :upgrade
          end

          opt.on('-U', '--upgrade-to <VERSION>', 'Upgrade to a specific VERSION') do |v|
            options.version = v
            options.operation = :upgrade_to
          end

          opt.separator ''
          opt.separator 'Options:'

          opt.on('--[no-]only-enabled', 'Include or not the disabled repositories') do |o|
            options.only_enabled = o
          end

          opt.on('--only-repo <NUMBER>[,NUMBER2,...]', 'Include only the repositories specified by NUMBER') do |o|
            options.list = o.split(',').map(&:to_i)
          end

          opt.on('--[no-]name', 'Upgrade or not the name') do |o|
            options.name = o
          end

          opt.on('--[no-]alias', 'Upgrade or not the alias') do |o|
            options.alias = o
          end

          opt.on('--[no-]hint', 'Suggest a new url when the current is not found') do |o|
            options.hint = o
          end

          opt.on('--override-url <NUMBER>,<URL>', Array, 'Overwrite the repository\'s url NUMBER with URL') do |r|
            options.overrides[r[0]] = r[1]
          end

          opt.on('--timeout <SECONDS>', "Adjust the waiting SECONDS used to catch an HTTP Timeout Error (Default: #{options.timeout})") do |o|
            options.timeout = o.to_f
          end

          opt.separator ''
          opt.separator 'View options:'

          opt.on('--sort-by-alias', 'Sort repositories by alias (Default)') do |o|
            options.sort_by = :alias
          end

          opt.on('--sort-by-name', 'Sort repositories by name') do |o|
            options.sort_by = :name
          end

          opt.on('--sort-by-priority', 'Sort repositories by priority') do |o|
            options.sort_by = :priority
          end

          opt.on('--report-view', 'View the data as report') do |o|
            options.view = :report
          end


          unless ENV['ZYPPER_UPGRADEREPO']
            opt.separator ''
            opt.separator 'Other:'

            opt.on_tail('-h', '--help', 'Show this message') do |o|
              puts opt
              exit
            end

            opt.on_tail('-v', '--version', 'Show version') do |o|
              puts VERSION
              exit
            end
          end

        end

        if ARGV.empty?
          puts opt_parser; exit
        else
          opt_parser.parse!(ARGV)
        end

        options
      end

    end


    class CLI
      def self.start
        begin
          options = OptParseMain.parse(ARGV)
          Upgraderepo::Builder.new(options).send(options.operation)
         rescue => e
           Messages.error e
           exit 1
         end
      end
    end
  end
end
