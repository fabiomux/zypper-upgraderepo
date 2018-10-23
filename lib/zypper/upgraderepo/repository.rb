require 'iniparse'

module Zypper
  module Upgraderepo


    class RepositoryList

      REPOSITORY_PATH = '/etc/zypp/repos.d'

      attr_reader :list, :max_col

      def initialize(options)
        @alias = options.alias
        @name = options.name
        @overrides = options.overrides
        @list = []

        Dir.glob(File.join(REPOSITORY_PATH, '*.repo')).each do |i|
          r = RepositoryRequest.new(Repository.new(i), options.timeout)
          next if options.only_enabled && (!r.enabled?)
          @list << r
        end
        @max_col = @list.max_by { |x| x.name.length }.name.length

        @list.sort_by! { |x| x.alias }
        @list.sort_by! { |x| x.send(options.sort_by) } if options.sort_by != :alias
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

      def priority
        @repo[@key]['priority'] || 99
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

      def save
        raise InvalidPermissions, @filename unless File.writable? @filename
        @repo.save(@filename)
      end


      private

      def get_key
        @repo.to_hash.keys.delete_if {|k| k == '0'}.pop
      end
    end


  end
end
