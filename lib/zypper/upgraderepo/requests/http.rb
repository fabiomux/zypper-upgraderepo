require 'delegate'
require 'net/http'

module Zypper
  module Upgraderepo

    class PageRequest < SimpleDelegator

      attr_reader :page

      USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0'

      def initialize(obj, timeout = 60)
        super obj
        @timeout = timeout
      end

      def available?
        ping.is_a?(Net::HTTPSuccess)
      end

      def redirected?
        ping.is_a?(Net::HTTPRedirection)
      end

      def redirected_to
        ping['location']
      end

      def not_found?
        ping.is_a?(Net::HTTPNotFound)
      end

      def forbidden?
        ping.is_a?(Net::HTTPForbidden)
      end

      def timeout?
        ping.is_a?(Net::HTTPRequestTimeOut)
      end

      def status
        ping.class.to_s
      end

      def cache!
        @page = nil
      end


      private

      def get_request(uri, head)

        if head
          request = Net::HTTP::Head.new(uri.request_uri)
        else
          request = Net::HTTP::Get.new(uri.request_uri)
        end

        request['User-Agent'] = USER_AGENT

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = @timeout

        http.request(request)
      end

      def ping(uri = nil, head = true, cache = true)
        begin
          if @page.nil? || uri
            if cache
              @page = get_request(uri, head)
            else
              unpage = get_request(uri, head)
            end
          end
        rescue SocketError
          raise NoConnection
        rescue Net::OpenTimeout
          @page = Net::HTTPRequestTimeOut.new('1.1', '', '')
        end
        cache ? @page : unpage
      end

    end


    module Requests

      class HttpRequest < PageRequest

        include Traversable

        def max_drop_back; 0; end

        def self.register_protocol; ['https', 'http'] end

        def self.domain; 'default' end

        def evaluate_alternative(version)
          if not_found?
            return traverse_url(URI(url), version)
          elsif redirected?
            return { url: redirected_to, message: 'Redirected to:' }
          end
        end


        private

        def get_request(uri, head)
          #super uri || URI(url), head
          super uri || repodata_uri, head
        end

        def has_repodata?(uri)
          ping(repodata_uri(uri), true, false).is_a?(Net::HTTPSuccess)
        end

        def subfolders(uri)
          ping.body.to_s.scan(Regexp.new('href=[\'\"][^\/\"]+\/[\'\"]')).delete_if do |x|
            x =~ /^\// || x =~ /^\.\./ || x =~ /\:\/\// || x =~ /href=[\"\'](media\.1|boot|EFI)\/[\"\']/
          end.uniq.map do |d|
            d.scan(/href=[\"\']([^"]+)[\'\"]/).pop.pop
          end
        end
      end

      class DownloadOpensuseOrgRequest < HttpRequest

        def self.domain; 'download.opensuse.org' end

        def subfolders(uri)
          u = URI(uri.to_s)
          u.path = "/download#{u.path}"
          u.query = 'jsontable'
          require 'json'
          JSON.parse(ping(u, false).body.to_s)["data"].map { |x| x["name"] }
        end
      end

    end

  end
end
