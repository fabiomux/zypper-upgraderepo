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

    class TableView

      def self.available(num, repo, max_col)
        Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} |")
      end

      def self.redirected(num, repo, max_col, redirected)
        Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{'Redirection'.bold.yellow} of #{repo.url} ")
        puts " #{' ' * 3} | #{' ' * 2} | #{ ' ' * max_col} | #{ ' ' * 3 } | #{'To:'.bold.yellow} #{redirected}"
      end

      def self.not_found(num, repo, max_col)
        Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} |")
      end

      def self.alternative(num, repo, max_col, alt)
        Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{alt[:message].bold.yellow}")
        puts " #{' ' * 3} | #{' ' * 2} | #{' ' * max_col} | #{' ' * 3} | #{alt[:url]}" unless alt[:url].to_s.empty?
      end

      def self.separator
        puts '-' * 90
      end

      def self.header(max_col)
        puts " St. |  # | #{'Name'.ljust(max_col, ' ')} | En. | Hint"
      end

      def self.footer
        self.separator
      end
    end


    class ReportView
      
      def self.available(num, repo, max_col)
        puts " #{num.to_s.rjust(2).bold.green} | Status: #{'Ok'.bold.green}"
        self.info(repo)
      end

      def self.redirected(num, repo, max_col, redirected)
        puts " #{num.to_s.rjust(2).bold.yellow} | Status: #{'Redirected'.bold.yellow}"
        puts " #{' ' * 2} | #{'To:'.bold.yellow} #{redirected}"
        self.info(repo)
      end

      def self.not_found(num, repo, max_col)
        puts " #{num.to_s.rjust(2).bold.red} | Status: #{'Not Found'.bold.red}"
        self.info(repo)
      end

      def self.alternative(num, repo, max_col, alt)
        puts " #{num.to_s.rjust(2).bold.red} | Status: #{'Not Found'.bold.red}"
        puts " #{' ' * 2} | Hint: #{alt[:message].bold.yellow}"
        puts " #{' ' * 2} | #{'Suggested:'.bold.yellow} #{alt[:url]}" unless alt[:url].to_s.empty?
        self.info(repo)
      end

      def self.separator
        puts '-' * 90
      end

      def self.header(max_col)
        puts "  # | Report"
      end

      def self.footer
        self.separator
      end

      private

      def self.info(repo)
        puts " #{ ' ' * 2 } | Name: #{repo.name}"
        puts " #{ ' ' * 2 } | Alias: #{repo.alias}"
        puts " #{ ' ' * 2 } | Url: #{repo.url}"
        puts " #{ ' ' * 2 } | Priority: #{repo.priority}"
        puts " #{ ' ' * 2 } | #{repo.enabled? ? 'Enabled: Yes' : 'Enabled: No'.yellow}"
        puts " #{ ' ' * 2 } | Filename: #{repo.filename}"
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

    class InvalidPermissions < StandardError
      def initialize(filename)
        super "Don't have the right permission to write #{filename}"
      end
    end

    class AlreadyUpgraded < StandardError
      def initialize(version)
        super "The system is already upgraded to #{version}"
      end
    end

    class NoConnection < StandardError
      def initialize
        super 'Internet connection has some trouble'
      end
    end
  end
end
