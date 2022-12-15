require 'iniparse'

module Zypper
  module Upgraderepo


    class OsRelease

      attr_reader :custom, :unstable

      OS_VERSIONS = ['13.1', '13.2', '42.1', '42.2', '42.3', '15.0', '15.1', '15.2', '15.3', '15.4']

      UNSTABLE_VERSION = '15.5'

      OS_RELEASE_FILE = '/etc/os-release'

      SUSE_RELEASE_FILE = '/etc/SuSE-release'

      def initialize(options)

        if options.allow_unstable
          raise NoUnstableVersionAvailable if UNSTABLE_VERSION.empty?
          OS_VERSIONS << UNSTABLE_VERSION
          @unstable = true
        end

        fname = if File.exist? self.class::OS_RELEASE_FILE
                  self.class::OS_RELEASE_FILE
                elsif File.exist? self.class::SUSE_RELEASE_FILE
                  self.class::SUSE_RELEASE_FILE
                else
                  raise ReleaseFileNotFound
                end
        @release = IniParse.parse(File.read(fname))
        @current_idx = OS_VERSIONS.index(@release['__anonymous__']['VERSION'].delete('"'))

        if options.version
          raise InvalidVersion, options.version unless OS_VERSIONS.include?(options.version)
          @custom = options.version
        end
      end

      def current
        OS_VERSIONS[@current_idx]
      end

      def last
        OS_VERSIONS[-1]
      end

      def next
        unless last?
          OS_VERSIONS[@current_idx.next]
        else
          nil
        end
      end

      def previous
        unless first?
          OS_VERSIONS[@current_idx.pred]
        else
          nil
        end
      end

      def fullname
        @release['__anonymous__']['PRETTY_NAME'].gsub(/"/, '')
      end

      def seniority
        OS_VERSIONS.count - @current_idx.next
      end

      def newer
        if seniority > 0
          OS_VERSIONS[@current_idx.next..-1]
        else
          []
        end
      end

      def last?
        @current_idx == (OS_VERSIONS.count - 1)
      end

      def first?
        @current_idx == 0
      end

      def valid?(version)
        OS_VERSIONS.include? version
      end

      def current?(version)
        OS_VERSIONS.index(version) == @current_idx
      end
    end


  end
end
