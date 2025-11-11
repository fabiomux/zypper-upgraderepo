# frozen_string_literal: true

module Zypper
  #
  # Collection of util classes.
  #
  module Upgraderepo
    #
    # String class patch.
    #
    class ::String
      def black
        "\033[30m#{self}\033[0m"
      end

      def red
        "\033[31m#{self}\033[0m"
      end

      def green
        "\033[32m#{self}\033[0m"
      end

      def yellow
        "\033[33m#{self}\033[0m"
      end

      def blue
        "\033[34m#{self}\033[0m"
      end

      def magenta
        "\033[35m#{self}\033[0m"
      end

      def cyan
        "\033[36m#{self}\033[0m"
      end

      def gray
        "\033[37m#{self}\033[0m"
      end

      def bg_black
        "\033[40m#{self}\0330m"
      end

      def bg_red
        "\033[41m#{self}\033[0m"
      end

      def bg_green
        "\033[42m#{self}\033[0m"
      end

      def bg_brown
        "\033[43m#{self}\033[0m"
      end

      def bg_blue
        "\033[44m#{self}\033[0m"
      end

      def bg_magenta
        "\033[45m#{self}\033[0m"
      end

      def bg_cyan
        "\033[46m#{self}\033[0m"
      end

      def bg_gray
        "\033[47m#{self}\033[0m"
      end

      def bold
        "\033[1m#{self}\033[22m"
      end

      def reverse_color
        "\033[7m#{self}\033[27m"
      end

      def cr
        "\r#{self}"
      end

      def clean
        "\e[K#{self}"
      end

      def new_line
        "\n#{self}"
      end

      def none
        self
      end
    end

    #
    # Default error code.
    #
    class ::StandardError
      def error_code
        1
      end
    end

    #
    # Color the error message.
    #
    class Messages
      def self.error(err)
        if err.instance_of?(String)
          puts " [E] ".bold.red + err
        elsif err.instance_of?(Interruption)
          warn err.message =~ /\(/ ? err.message.gsub(/.*\((.*)\).*/, '\1').green : err.message.green
        else
          warn "Error! ".bold.red + err.message
        end
      end

      def self.ok(msg)
        puts " [V] ".bold.green + msg
      end

      def self.warning(msg)
        puts " [W] ".bold.yellow + msg
      end
    end

    #
    # File not found error.
    #
    class FileNotFound < StandardError
      def initialize(filename)
        super("The File #{filename} doesn't exist.")
      end
    end

    #
    # Osrelease file not found.
    #
    class ReleaseFileNotFound < StandardError
      def initialize
        super("The release file is not found.")
      end
    end

    #
    # Invalid repository protocol.
    #
    class InvalidProtocol < StandardError
      def initialize(repo)
        super("The repository #{repo.name} has an unknown protocol: #{repo.protocol}; disable it to continue.")
      end
    end

    #
    # Invalid release version.
    #
    class InvalidVersion < StandardError
      def initialize(version)
        super("The version #{version} is not valid")
      end
    end

    #
    # Repository file writing not allowed.
    #
    class InvalidWritePermissions < StandardError
      def initialize(filename)
        super("Don't have the permissions to write #{filename}")
      end

      def error_code
        4
      end
    end

    #
    # An application is running an update.
    #
    class SystemUpdateRunning < StandardError
      def initialize(args)
        super("The application #{args[:process].bold} with pid #{args[:pid].bold} is running a system update!")
      end

      def error_code
        5
      end
    end

    #
    # The repository URL can't be interpolated.
    #
    class UnableToUpgrade < StandardError
      def initialize(args)
        super("The repository n.#{args[:num].to_s.bold.red} named #{args[:repo].name.bold.red} " \
              "can't be upgraded, a manual check is required!")
      end

      def error_code
        7
      end
    end

    #
    # Repository with missing URL.
    #
    class MissingOverride < StandardError
      def initialize(args)
        super("The repository n.#{args[:num].to_s.bold.red} named #{args[:ini]["name"].bold.red} " \
              "doesn't contain the URL key!")
      end

      def error_code
        8
      end
    end

    #
    # Repository overrides failure.
    #
    class UnmatchingOverrides < StandardError
      def initialize(args)
        super("The repository n.#{args[:num]} named #{args[:repo].name.bold.red} doesn't match with " \
              "the repository named #{args[:ini]["name"].bold.red} in the ini file")
      end

      def error_code
        9
      end
    end

    #
    # The system doesn't require any upgrade.
    #
    class AlreadyUpgraded < StandardError
      def initialize(version)
        super("The system is already upgraded to the #{version} version")
      end

      def error_code
        2
      end
    end

    #
    # There are not unstable versions,
    #
    class NoUnstableVersionAvailable < StandardError
      def initialize
        super("No unstable version is available, remove the --allow-unstable switch to continue")
      end

      def error_code
        11
      end
    end

    #
    # No internet connection.
    class NoConnection < StandardError
      def initialize
        super("Internet connection has some trouble")
      end

      def error_code
        6
      end
    end

    #
    # Ctrl + C message error.
    #
    class Interruption < StandardError
      def initialize
        super("Ok ok... Exiting!")
      end
    end

    Signal.trap("INT") { raise Interruption }
    Signal.trap("TERM") { raise Interruption }
  end
end
