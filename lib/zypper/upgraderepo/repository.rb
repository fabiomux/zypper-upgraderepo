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
        @only_enabled = options.only_enabled
        @only_invalid = options.only_invalid
        @only_protocols = options.only_protocols
        @overrides = options.overrides
        @upgrade_options = {alias: options.alias, name: options.name}
        @list = []

        Dir.glob(File.join(REPOSITORY_PATH, '*.repo')).each do |i|
          r = Request.build(Repository.new(i), options.timeout)
          @list << r
        end
        @max_col = @list.max_by { |r| r.name.length }.name.length

        @list = @list.sort_by { |r| r.alias }.map.with_index(1) { |r, i| { num: i, repo: r } }

        @list.sort_by! { |x| x[:repo].send(options.sort_by) } if options.sort_by != :alias

        load_overrides(options.filename) if options.filename
      end

      def only_enabled?
        @only_enabled
      end

      def upgrade!(version)
        each_with_number(only_invalid: false) do |repo, num|
          repo.upgrade! version, @upgrade_options.merge(url_override: @overrides[num])
          repo.cache!
        end
      end

      def each_with_number(options = {})
        only_repo = options[:only_repo].nil? ? @only_repo : options[:only_repo]
        only_enabled = options[:only_enabled].nil? ? @only_enabled : options[:only_enabled]
        only_invalid = options[:only_invalid].nil? ? @only_invalid : options[:only_invalid]
        only_protocols = options[:only_protocols].nil? ? @only_protocols : options[:only_protocols]

        @list.each do |x|
          next if only_repo && !only_repo.include?(x[:num])
          next if only_enabled && !x[:repo].enabled?
          next if only_invalid && x[:repo].available?
          next if only_protocols && (!only_protocols.include?(x[:repo].protocol))

          yield x[:repo], x[:num] if block_given?
        end
      end

      def save
        @list.each do |i|
          i.save
        end
      end


      private

      def load_overrides(filename)
        raise FileNotFound, filename unless File.exist?(filename)
        ini = IniParse.parse(File.read(filename))
        each_with_number(only_invalid: false) do |repo, num|
          if x = ini["repository_#{num}"]
            repo.enable!(x['enabled'])
            raise UnmatchingOverrides, { num: num, ini: x, repo: repo } if repo.url != x['old_url']
            if (@repos.only_enabled?)
              raise MissingOverride, { num: num, ini: x } unless x['url'] || x['enabled'] =~ /no|false|0/i
            else
              raise MissingOverride, { num: num, ini: x } unless x['url']
            end
            @overrides[num] = x['url'] if x['url']
          end
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

      def enable!(value = true)
        @repo[@key]['enabled'] = (value.to_s =~ /true|1|yes/i) ? 1 : 0
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

      def protocol
        URI(url.to_s).scheme
      end

      def unversioned?
        (url =~ /\d\d\.\d/).nil?
      end

      def versioned?
        !unversioned?
      end

      def alias
        @key
      end

      def alias=(value)
        @repo = IniParse.parse(@repo.to_ini.sub(/\[[^\]]+\]/, "[#{value}]"))
        @key = get_key
      end

      def upgrade!(version, args = {})
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
