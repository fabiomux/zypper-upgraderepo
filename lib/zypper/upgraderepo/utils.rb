module Zypper
  module Upgraderepo

    class ::String
      def black;          "\033[30m#{self}\033[0m" end
      def red;            "\033[31m#{self}\033[0m" end
      def green;          "\033[32m#{self}\033[0m" end
      def yellow;         "\033[33m#{self}\033[0m" end
      def blue;           "\033[34m#{self}\033[0m" end
      def magenta;        "\033[35m#{self}\033[0m" end
      def cyan;           "\033[36m#{self}\033[0m" end
      def gray;           "\033[37m#{self}\033[0m" end
      def bg_black;       "\033[40m#{self}\0330m"  end
      def bg_red;         "\033[41m#{self}\033[0m" end
      def bg_green;       "\033[42m#{self}\033[0m" end
      def bg_brown;       "\033[43m#{self}\033[0m" end
      def bg_blue;        "\033[44m#{self}\033[0m" end
      def bg_magenta;     "\033[45m#{self}\033[0m" end
      def bg_cyan;        "\033[46m#{self}\033[0m" end
      def bg_gray;        "\033[47m#{self}\033[0m" end
      def bold;           "\033[1m#{self}\033[22m" end
      def reverse_color;  "\033[7m#{self}\033[27m" end
      def cr;             "\r#{self}" end
      def clean;          "\e[K#{self}" end
      def new_line;       "\n#{self}" end
    end


    class Messages

      def self.error(e)
        if e.class == String
          puts ' [E] '.bold.red + e
        elsif e.class == Interruption
          STDERR.puts e.message =~ /\(/ ? e.message.gsub(/.*\((.*)\).*/, '\1').green : e.message.green
        else
          STDERR.puts 'Error! '.bold.red + e.message
        end
      end

      def self.ok(m)
        puts ' [V] '.bold.green + m
      end

      def self.warning(m)
        puts ' [W] '.bold.yellow + m
      end

    end


    class ReleaseFileNotFound < StandardError
      def initialize
        super 'The release file is not found.'
      end
    end

    class InvalidVersion < StandardError
      def initialize(version)
        super "The version #{version} is not valid"
      end
    end

    class InvalidWritePermissions < StandardError
      def initialize(filename)
        super "Don't have the right permission to write #{filename}"
      end
    end

    class SystemUpdateRunning < StandardError
      def initialize(args)
        super "The application #{args[:process].bold} with pid #{args[:pid].bold} is running a system update!"
      end
    end

    class UnableToUpgrade < StandardError
      def initialize(args)
        super "The repository n.#{args[:num].to_s.bold.red} named #{args[:repo].name.bold.red} can't be upgraded, a manual check is required!"
      end
    end

    class AlreadyUpgraded < StandardError
      def initialize(version)
        super "The system is already upgraded to the #{version} version"
      end
    end

    class NoConnection < StandardError
      def initialize
        super 'Internet connection has some trouble'
      end
    end

    class Interruption < StandardError
      def initialize
        super 'Ok ok... Exiting!'
      end
    end

    Signal.trap('INT') { raise Interruption }

    Signal.trap('TERM') { raise Interruption }
  end
end
