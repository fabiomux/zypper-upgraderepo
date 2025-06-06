# frozen_string_literal: true

require "iniparse"

module Zypper
  module Upgraderepo
    #
    # Calculate and apply the variables that can be
    # declared within the repository metadata.
    #
    class RepositoryVariables
      VARIABLE_PATH = "/etc/zypp/vars.d"

      VAR_CPU_ARCH, VAR_ARCH = `rpm --eval "%cpu_arch;%_arch"`.tr("\n", "").split(";")

      attr_reader :variables

      def initialize(version)
        @variables = {
          releasever_major: version.split(".")[0],
          releasever_minor: version.split(".")[1],
          releasever: version,
          basearch: VAR_ARCH,
          arch: VAR_CPU_ARCH
        }

        Dir.glob(File.join(self.class::VARIABLE_PATH, "*")).each do |i|
          @variables[File.basename(i).to_sym] = File.read(i).strip
        end
      end

      def apply(str)
        str.gsub(/\${?([a-zA-Z0-9_]+)}?/) do
          last = Regexp.last_match(1)
          @variables[last.to_sym] || "<Unknown var: $#{last}>"
        end
      end
    end

    #
    # Handle the repository collection.
    #
    class RepositoryList
      REPOSITORY_PATH = "/etc/zypp/repos.d"

      attr_reader :list, :max_col

      def initialize(options, variables)
        @alias = options.alias
        @name = options.name
        @only_repo = options.only_repo
        @only_enabled = options.only_enabled
        @only_invalid = options.only_invalid
        @only_protocols = options.only_protocols
        @overrides = options.overrides
        @upgrade_options = { alias: options.alias, name: options.name }
        @list = []

        @variables = variables
        Dir.glob(File.join(self.class::REPOSITORY_PATH, "*.repo")).each do |i|
          r = Request.build(Repository.new(i, @variables), options.timeout)
          @list << r
        end
        @max_col = @list.max_by { |r| r.name.length }.name.length

        @list = @list.sort_by(&:alias).map.with_index(1) { |r, i| { num: i, repo: r } }

        @list.sort_by! { |x| x[:repo].send(options.sorting_by) } if options.sorting_by != :alias

        @only_repo = select_repos(@only_repo) unless @only_repo.nil?

        load_overrides(options.overrides_filename) if options.overrides_filename
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
          next if only_protocols && !only_protocols.include?(x[:repo].protocol)

          yield x[:repo], x[:num] if block_given?
        end
      end

      def save
        each_with_number do |repo, _num|
          repo.save
        end
      end

      private

      def select_repos(repos)
        res = []
        repos.each do |r|
          if r.to_i.positive?
            res.push r.to_i
          elsif r =~ /^\ *@.*/
            a = r.gsub(/@/, "").strip
            @list.select { |x| x[:repo].alias.match?(Regexp.new(a, "i")) }.each do |l|
              res.push l[:num]
            end
          elsif r =~ /^\ *\#.*/
            u = r.gsub(/\#/, "").strip
            @list.select { |x| x[:repo].url.match?(Regexp.new(u, "i")) }.each do |l|
              res.push l[:num]
            end
          elsif r =~ /^\ *&.*/
            s = r.gsub(/&/, "").strip
            sel = @list.select do |x|
              x[:repo].alias.match?(Regexp.new(s, "i")) ||
                x[:repo].name.match?(Regexp.new(s, "i")) ||
                x[:repo].url.match?(Regexp.new(s, "i"))
            end
            sel.each do |l|
              res.push l[:num]
            end
          else
            n = r.strip
            @list.select { |x| x[:repo].name.match?(Regexp.new(n, "i")) }.each do |l|
              res.push l[:num]
            end
          end
        end

        res.uniq
      end

      def load_overrides(filename)
        raise FileNotFound, filename unless File.exist?(filename)

        ini = IniParse.parse(File.read(filename))
        each_with_number(only_invalid: false) do |repo, num|
          next unless (x = ini["repository_#{num}"])

          repo.enable!(x["enabled"])
          raise UnmatchingOverrides, { num: num, ini: x, repo: repo } if repo.url != x["old_url"]

          if only_enabled?
            raise MissingOverride, { num: num, ini: x } unless x["url"] || x["enabled"] =~ /no|false|0/i
          else
            raise MissingOverride, { num: num, ini: x } unless x["url"]
          end
          @overrides[num] = x["url"] if x["url"]
        end
      end
    end

    #
    # Single repository class.
    #
    class Repository
      attr_reader :filename, :old_url, :old_alias, :old_name

      def initialize(filename, variables)
        @filename = filename
        @repo = IniParse.parse(File.read(filename))
        @key = read_key
        @old_url = nil
        @old_name = nil
        @old_alias = nil
        resolve_variables!(variables)
      end

      def enabled?
        @repo[@key]["enabled"].to_i == 1
      end

      def enable!(value = nil)
        @repo[@key]["enabled"] = (value || true).to_s =~ /true|1|yes/i ? 1 : 0
      end

      def type
        @repo[@key]["type"]
      end

      def name
        @repo[@key]["name"] || @key
      end

      def name=(value)
        @repo[@key]["name"] = value
      end

      def priority
        @repo[@key]["priority"] || 99
      end

      def url
        @repo[@key]["baseurl"]
      end

      def url=(value)
        @repo[@key]["baseurl"] = value
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
        @key = read_key
      end

      def upgrade!(version, args = {})
        @old_url ||= url
        @old_alias ||= self.alias
        @old_name ||= name

        self.url = (args[:url_override] || url.gsub(/\d\d\.\d/, version))

        self.alias = self.alias.gsub(/\d\d\.\d/, version) if args[:alias]
        self.name = name.gsub(/\d\d\.\d/, version) if args[:name]
      end

      def upgraded?(item = :url)
        !send("old_#{item}").nil? && (send("old_#{item}") != send(item))
      end

      def save
        raise InvalidWritePermissions, @filename unless File.writable? @filename

        process, pid = libzypp_process
        raise SystemUpdateRunning, { pid: pid, process: process } if pid

        @repo.save(@filename)
      end

      private

      def resolve_variables!(variables)
        self.url = variables.apply(url) if url =~ /\$/
        self.name = variables.apply(name) if name =~ /\$/
        self.alias = variables.apply(self.alias) if self.alias =~ /\$/

        self
      end

      def libzypp_process
        libpath = `ldd /usr/bin/zypper | grep "libzypp.so"`.split(" => ")[1].split.shift
        process = `sudo lsof #{libpath} | tail -n 1`
        process, pid = process.split
        [process, pid]
      end

      def read_key
        @repo.to_hash.keys.delete_if { |k| k == "0" }.pop
      end
    end
  end
end
