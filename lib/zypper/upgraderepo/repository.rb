require 'iniparse'
require 'net/http'
require 'zlib'
require 'minitar'

module Zypper
  module Upgraderepo


    class RepositoryList
      attr_reader :list, :max_col

      def initialize(options)
        @alias = options.alias
        @name = options.name
        @overrides = options.overrides
        @list = []
        @backup_path = options.backup_path

        Dir.glob('/etc/zypp/repos.d/*.repo').sort.each do |i|
          r = Repository.new(i)
          next if options.only_enabled && (!r.enabled?)
          @list << r
        end
        @max_col = @list.max_by { |x| x.name.length }.name.length
      end

      def backup
        filename = File.join(@backup_path, "repos-backup-#{Time.now.to_s.delete(': +-')[0..-5]}.tgz")
        raise InvalidPermissions, filename unless File.writable? @backup_path
        Minitar.pack('/etc/zypp/repos.d',
                     Zlib::GzipWriter.new(File.open(filename, 'wb'))) 
      end

      def upgrade(version)
        @list.each_with_index do |repo, i|
          if @overrides.has_key? i.next.to_s
            repo.url = @overrides[i.next.to_s]
          else
            repo.url = repo.url.gsub(/\d\d\.\d/, version)
          end
          repo.alias = repo.alias.gsub(/\d\d\.\d/, version) if @alias
          repo.name = repo.name.gsub(/\d\d\.\d/, version) if @name
        end
      end

      def save
        @list.each do |i|
          i.save
        end
      end
    end


    class Repository
      attr_reader :filename
 
      def initialize(filename)
        @filename = filename
        @repo = IniParse.parse(File.read(filename))
        @key = get_key 
        @res = nil
      end

      def enabled?
        @repo[@key]['enabled'].to_i == 1
      end

      def type
        @repo[@key]['type']
      end

      def name
        @repo[@key]['name'] || @key
      end

      def name=(value)
        @repo[@key]['name'] = value
      end

      def url
        @repo[@key]['baseurl']
      end

      def url=(value)
        @repo[@key]['baseurl'] = value
      end

      def alias
        @key
      end

      def alias=(value)
        @repo = IniParse.parse(@repo.to_ini.sub(/\[[^\]]+\]/, "[#{value}]"))
        @key = get_key
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

      def save
        raise InvalidPermissions, @filename unless File.writable? @filename
        @repo.save(@filename) 
      end

      def evaluate_alternative(version)
        if url =~ /dl\.google\.com/
          return { url: '', message: 'Just Google security, use this repo anyway ;)'}
        elsif not_found?
          return traverse_url(URI(url.clone), version)
        elsif redirected?
          return { url: redirected_to, message: 'Redirected to:' }
        end
      end

      private

      def ping(uri = URI(url), force = false)
        begin
          @res = Net::HTTP.get_response(uri) if @res.nil? || force
        rescue SocketError
          raise NoConnection
        end
        @res
      end

      def get_key
        @repo.to_hash.keys.delete_if {|k| k == '0'}.pop
      end

      def traverse_url(uri, version)
        uri.path = File.dirname(uri.path)

        return {url: '', message: 'None, try to find it manually'} if uri.path == '/'
         
        uri.path += '/'
        ping(uri, true)

        if not_found? 
          return traverse_url(uri, version)
        elsif available?
          return {url: uri.to_s, message: 'Override with this one' } if uri.path =~ Regexp.new(version)

          path = ping.body.to_s.scan(Regexp.new("href=\"[^\"]*#{version}[^\"]*\"")).uniq
          unless path.empty?
            uri.path += "#{path.pop.scan(/href="(.*)"/).pop.pop }"
            return {url: uri.to_s, message: 'Override with this one' } 
          end

          return {url: url, message: 'Can\'t find anything similar, try manually!' }
        end
          
      end
    end


  end
end
