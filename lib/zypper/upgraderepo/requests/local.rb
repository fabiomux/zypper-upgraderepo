# frozen_string_literal: true

require "delegate"

module Zypper
  module Upgraderepo
    #
    # Base class for a local directory request.
    #
    class DirRequest < SimpleDelegator
      attr_reader :dir_path

      def initialize(obj, _timeout)
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

      def ping(uri = nil, head: true)
        @dir_path ||= URI(url).path

        @dir_path = uri.to_s =~ %r{^/} ? uri.to_s : URI(uri.to_s).path if uri

        URI.unescape(@dir_path)
      end
    end

    module Requests
      #
      # This is where the local repositories are
      # analyzed to find newer versions.
      #
      class LocalRequest < DirRequest
        include Traversable

        def max_drop_back
          1
        end

        def self.register_protocol
          ["dir"]
        end

        def self.domain
          "default"
        end

        def evaluate_alternative(version)
          if not_found?
            traverse_url(URI(url), version)
          elsif redirected?
            { url: redirected_to, message: "Linked to" }
          end
        end

        private

        def repodata?(uri)
          File.exist? URI.unescape(repodata_uri(uri).path)
        end

        def subfolders
          Dir.glob("#{ping.gsub(%r{/$}, "")}/*/").map do |x|
            URI.escape(x.gsub(%r{/$}, "").gsub(ping, "").gsub(%r{^/}, ""))
          end
        end
      end
    end
  end
end
