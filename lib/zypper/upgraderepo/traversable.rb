module Zypper
  module Upgraderepo

    module Traversable

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


      private

      def traverse_url_backward(uri, version)
        uri.path = File.dirname(uri.path)

        return nil if uri.path == '/' || uri.path == '.' || (versioned? && (drop_back_level(uri) > max_drop_back))

        uri.path += '/' if uri.path[-1] != '/'
        ping(uri, false)

        if not_found?
          return traverse_url_backward(uri, version)
        elsif available?
          if res = traverse_url_forward(uri, version)
            return res
          else
            return traverse_url_backward(uri, version)
          end
        elsif forbidden?
          return { url: uri.to_s, message: 'Try to replace with this one' } if has_repodata?(uri)

          return traverse_url_backward(uri, version)
        end

        nil
      end

      def traverse_url_forward(uri, version)
        uri.path += '/' if uri.path[-1] != '/'
        ping(uri, false)

        subfolders.each do |dir|
          u = URI(uri.to_s)
          u.path += dir

          if has_repodata?(u)
            if (versioned?) && (u.to_s =~ /#{version}/)
              return { url: u.to_s, message: 'Override with this one' }
            end
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
      
      def drop_back_level(uri)
        URI(url).path.split('/').index { |x| x =~ /\d\d.\d/ } - uri.path.split('/').count
      end
      
      # to implement on each repository type class
      #
      # def has_repodata?(uri)
      #
      # def subfolders

    end
  end
end
