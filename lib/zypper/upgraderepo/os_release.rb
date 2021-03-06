require 'iniparse'

module Zypper
  module Upgraderepo


    class OsRelease

      attr_reader :custom

      OS_VERSIONS = ['13.1', '13.2', '42.1', '42.2', '42.3', '15.0', '15.1', '15.2', '15.3']


      def initialize(options)
        fname = if File.exist? '/etc/os-release'
                  '/etc/os-release'
                elsif File.exist? '/etc/SuSE-release'
                  '/etc/SuSE-release'
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
