# frozen_string_literal: true

module Zypper
  module Upgraderepo
    #
    # Mixin module that introduces the generic procedures
    # used to traverse the repository path and query the
    # system to discover wheter or not the upgraded folder
    # exists.
    #
    module Traversable
      def traverse_url(uri, version)
        ping(uri)

        if available? && !repodata?(uri)
          return { url: "", message: "This repository doesn't seem working and should be disabled." }
        elsif forbidden?
          res =  { url: url, message: "Can't navigate through the repository!" }
        elsif available? && uri.to_s =~ /#{version}/
          res = traverse_url_forward(uri, version)
        else
          res = traverse_url_backward(uri, version)
        end

        res || { url: "", message: "Can't find a valid alternative, try manually!" }
      end

      private

      def traverse_url_backward(uri, version)
        uri.path = File.dirname(uri.path)

        return nil if uri.path == "/" || uri.path == "." || (versioned? && (drop_back_level(uri) > max_drop_back))

        uri.path += "/" if uri.path[-1] != "/"
        ping(uri, head: false)

        if not_found?
          return traverse_url_backward(uri, version)
        elsif available?
          res = traverse_url_forward(uri, version)
          return res if res

          return traverse_url_backward(uri, version)

        elsif forbidden?
          return { url: uri.to_s, message: "Try to replace with this one" } if repodata?(uri)

          return traverse_url_backward(uri, version)
        end

        nil
      end

      def traverse_url_forward(uri, version)
        uri.path += "/" if uri.path[-1] != "/"
        ping(uri, head: false)

        subfolders(uri).each do |dir|
          u = URI(uri.to_s)
          u.path += dir

          if repodata?(u)
            return { url: u.to_s, message: "Override with this one" } if versioned? && (u.to_s =~ /#{version}/)
          else
            res = traverse_url_forward(u, version)
            return res if res.instance_of?(Hash)
          end
        end

        nil
      end

      def repodata_uri(uri = nil)
        uri = if uri
                URI(uri.to_s)
              else
                URI(url)
              end

        uri.path = "#{uri.path.gsub(%r{/$}, "")}/repodata/repomd.xml"

        uri
      end

      def drop_back_level(uri)
        URI(url).path.split("/").index { |x| x =~ /\d\d.\d/ } - uri.path.split("/").count
      end

      # to implement on each repository type class
      #
      # def repodata?(uri)
      #
      # def subfolders
    end
  end
end
