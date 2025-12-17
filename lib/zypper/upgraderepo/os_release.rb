# frozen_string_literal: true

require "iniparse"

module Zypper
  module Upgraderepo
    #
    # Detect the current and next release.
    #
    class OsRelease
      attr_reader :custom, :unstable

      UNSTABLE_VERSION = "16.0"

      OS_RELEASE_FILE = "/etc/os-release"

      SUSE_RELEASE_FILE = "/etc/SuSE-release"

      def initialize(options)
        @os_versions = ["13.1", "13.2",
                        "42.1", "42.2", "42.3",
                        "15.0", "15.1", "15.2", "15.3", "15.4", "15.5", "15.6",
                        "16.0"]

        load_unstable if options.allow_unstable

        @release = IniParse.parse(File.read(release_filename))
        @current_idx = @os_versions.index(@release["__anonymous__"]["VERSION"].delete('"'))

        return unless options.version
        raise InvalidVersion, options.version unless @os_versions.include?(options.version)

        @custom = options.version
      end

      def current
        @os_versions[@current_idx]
      end

      def last
        @os_versions[-1]
      end

      def next
        return if last?

        @os_versions[@current_idx.next]
      end

      def previous
        return if first?

        @os_versions[@current_idx.pred]
      end

      def fullname
        @release["__anonymous__"]["PRETTY_NAME"].gsub('"', "")
      end

      def seniority
        @os_versions.count - @current_idx.next
      end

      def newer
        if seniority.positive?
          @os_versions[@current_idx.next..-1]
        else
          []
        end
      end

      def last?
        @current_idx == (@os_versions.count - 1)
      end

      def first?
        @current_idx.zero?
      end

      def valid?(version)
        @os_versions.include? version
      end

      def current?(version)
        @os_versions.index(version) == @current_idx
      end

      def requires_v2?(version)
        if `uname -m` =~ /x86_64/
          @os_versions.index(version) > 11
        else
          false
        end
      end

      def v2?
        flags = `cat /proc/cpuinfo`.split("\n").grep(/^flags.*:/).first.split
        %w[cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3].reduce(true) do |res, f|
          flags.include?(f) && res
        end
      end

      private

      def release_filename
        if File.exist? self.class::OS_RELEASE_FILE
          self.class::OS_RELEASE_FILE
        elsif File.exist? self.class::SUSE_RELEASE_FILE
          self.class::SUSE_RELEASE_FILE
        else
          raise ReleaseFileNotFound
        end
      end

      def load_unstable
        raise NoUnstableVersionAvailable if UNSTABLE_VERSION.empty?

        @os_versions << UNSTABLE_VERSION
        @unstable = true
      end
    end
  end
end
