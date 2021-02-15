require 'delegate'

module Zypper
  module Upgraderepo


    class DirRequest < SimpleDelegator

      attr_reader :dir_path

      def initialize(obj, timeout)
        super obj
      end

      def available?
        Dir.exist? ping
      end

      def redirected?
        File.symlink? ping
      end

      def redirected_to
        File.realpath ping
      end

      def not_found?
        !available?
      end

      def forbidden?
        File.readable? ping
      end

      def timeout?
        false
      end

      def status
        File.stat ping
      end

      def cache!
        @dir_path = nil
      end


      private

      def ping(uri = nil, head = true)
        @dir_path ||= URI(url).path

        @dir_path = uri.to_s =~ /^\// ? uri.to_s : URI(uri.to_s).path if uri

        URI.unescape(@dir_path)
      end

    end


    module Requests

      class LocalRequest < DirRequest

        include Traversable

        def max_drop_back; 1 end

        def self.register_protocol; ['dir'] end

        def evaluate_alternative(version)
          if not_found?
            return traverse_url(URI(url), version)
          elsif redirected?
            return { url: redirected_to, message: 'Linked to' }
          end
        end


        private

        def has_repodata?(uri)
          File.exist? URI.unescape(repodata_uri(uri).path)
        end

        def subfolders
          Dir.glob(ping.gsub(/\/$/, '') + '/*/').map { |x| URI.escape(x.gsub(/\/$/, '').gsub(ping, '').gsub(/^\//, '')) }
        end
      end

    end

  end
end
