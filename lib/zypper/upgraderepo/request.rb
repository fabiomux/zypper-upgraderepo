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


      private

      def get_request(uri, head)
        uri ||= repodata_uri

        if head
          request = Net::HTTP::Head.new(uri.request_uri)
        else
          request = Net::HTTP::Get.new(uri.request_uri)
        end

        request['User-Agent'] = USER_AGENT

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = @timeout

        http.request(request)
      end

      def ping(uri = nil, head = true)
        begin
          if @page.nil? || uri
            @page = get_request(uri, head)
          end
        rescue SocketError
          raise NoConnection
        rescue Net::OpenTimeout
          @page = Net::HTTPRequestTimeOut.new('1.1', '', '')
        end
        @page
      end

    end


    class RepositoryRequest < PageRequest

      def evaluate_alternative(version)

        if not_found?
          return traverse_url(URI(url), version)
        elsif redirected?
          return { url: redirected_to, message: 'Redirected to:' }
        end
      end


      private

      def traverse_url(uri, version)
        ping(uri)

        if forbidden?
          res =  { url: url, message: 'Can\'t navigate through the repository!' }
        elsif available? && uri.to_s =~ /#{version}/
          res = traverse_url_forward(uri, version)
        else
          res = traverse_url_backward(uri, version)
        end

        res || { url: '', message: 'Can\'t find a valid alternative, try manually!' }
      end

      def traverse_url_backward(uri, version)
        uri.path = File.dirname(uri.path)

        return nil if uri.path == '/' || uri.path == '.'

        uri.path += '/' if uri.path[-1] != '/'
        ping(uri, false)

        if not_found?
          return traverse_url_backward(uri, version)
        elsif available?

          if uri.path =~ /#{version}/ && repodata?
            return {url: uri.to_s, message: 'Override with this one' }
          elsif res = traverse_url_forward(uri, version, !(uri.path =~ /#{version}/))
            return res
          else
            return traverse_url_backward(uri, version)
          end

        elsif forbidden?
          return { url: uri.to_s, message: 'Try to replace with this one' } if repodata?(uri)

          return traverse_url_backward(uri, version)
        end

        nil
      end

      def traverse_url_forward(uri, version, check_version = false)
        uri.path += '/' if uri.path[-1] != '/'
        ping(uri, false)

        subfolders(version, check_version).each do |dir|
          u = URI(uri.to_s)
          u.path += dir

          if repodata?(u)
            return {url: u.to_s, message: 'Override with this one' }
          else
            res = traverse_url_forward(u, version)
            return res if res.class == Hash
          end
        end

        nil
      end

      def repodata_uri(uri = nil)
        if uri
          uri = URI(uri.to_s)
        else
          uri = URI(url)
        end

        uri.path = uri.path.gsub(/\/$/, '') + '/repodata/repomd.xml' 

        uri
      end

      def repodata?(uri = nil)
        if uri.nil?
          return ping.body.to_s.scan(Regexp.new("href=\"repodata/")).empty?
        else
          ping(repodata_uri(uri))
          return available?
        end
      end

      def subfolders(version, check_version)
        res = ping.body.to_s.scan(Regexp.new('href=[\'\"][^\/\"]+\/[\'\"]')).delete_if do |x|
          x =~ /^\// || x =~ /^\.\./ || x =~ /\:\/\// || x =~ /href=[\"\'](media\.1|boot|EFI)\/[\"\']/
        end.uniq.map do |d|
          d.scan(/href=[\"\']([^"]+)[\'\"]/).pop.pop
        end

        res = res.delete_if { |x| !(x =~ /#{version}/) } if check_version

        res
      end
    end


  end
end
