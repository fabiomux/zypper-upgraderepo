require 'iniparse'

module Zypper
  module Upgraderepo


    class RepositoryList

      REPOSITORY_PATH = '/etc/zypp/repos.d'

      attr_reader :list, :max_col

      def initialize(options)
        @alias = options.alias
        @name = options.name
        @only_repo = options.only_repo
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

      def each_with_index
        @list.each_with_index do |repo, i|
          next if @only_repo && !@only_repo.include?(i.next)

          yield repo, i if block_given?
        end
      end

      def save
        @list.each do |i|
          i.save
        end
      end
    end


    class Repository
      attr_reader :filename, :old_url, :old_alias, :old_name

      def initialize(filename)
        @filename = filename
        @repo = IniParse.parse(File.read(filename))
        @key = get_key
        @old_url = nil
        @old_name = nil
        @old_alias = nil
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

      def upgrade(version, args = {})
        @old_url ||= self.url
        @old_alias ||= self.alias
        @old_name ||= self.name

        if args[:url_override]
          self.url = args[:url_override]
        else
          self.url = self.url.gsub(/\d\d\.\d/, version)
        end

        self.alias = self.alias.gsub(/\d\d\.\d/, version) if args[:alias]
        self.name = self.name.gsub(/\d\d\.\d/, version) if args[:name]
      end

      def upgraded?(item = :url)
        (!self.send("old_#{item}").nil?) && (self.send("old_#{item}") != self.send(item))
      end

      def save
        raise InvalidWritePermissions, @filename unless File.writable? @filename
        process, pid = libzypp_process
        raise SystemUpdateRunning, { pid: pid, process: process } if pid
        @repo.save(@filename)
      end


      private

      def libzypp_process
        libpath = `ldd /usr/bin/zypper | grep "libzypp.so"`.split(' => ')[1].split(' ').shift
        process = `sudo lsof #{libpath} | tail -n 1`
        process, pid = process.split(' ')
        [process, pid]
      end

      def get_key
        @repo.to_hash.keys.delete_if {|k| k == '0'}.pop
      end
    end


  end
end
