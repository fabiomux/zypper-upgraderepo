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
    # rubocop: disable Metrics/ClassLength
    class RepositoryList
      REPOSITORY_PATH = "/etc/zypp/repos.d"

      attr_reader :list, :max_col

      def initialize(options, variables)
        initialize_options(options)

        @variables = variables

        initialize_list(options)

        @max_col = @list.max_by { |r| r.name.length }.name.length

        sort_list(options)

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

      # TODO: Allow --only-used/unused param as filter
      def each_with_number(options = {})
        f_o = filter_options(options)

        @list.each do |x|
          next if next_repo? x[:repo], x[:num], f_o

          yield x[:repo], x[:num] if block_given?
        end
      end

      def save
        each_with_number do |repo, _num|
          repo.save
        end
      end

      def unused?(num)
        `zypper -q pa -i -r #{num} 2>/dev/null|grep "^i"|wc -l`.strip.to_i.zero?
      end

      def duplicates
        group_for_url.delete_if { |_, v| v.length < 2 }
      end

      private

      def initialize_list(options)
        @list = []
        Dir.glob(File.join(self.class::REPOSITORY_PATH, "*.repo")).each do |i|
          r = Request.build(Repository.new(i, @variables), options.timeout)
          @list << r
        end
      end

      def sort_list(options)
        @list = @list.sort_by(&:alias).map.with_index(1) { |r, i| { num: i, repo: r } }
        @list.sort_by! { |x| x[:repo].send(options.sorting_by) } if options.sorting_by != :alias
      end

      def initialize_options(options)
        @alias = options.alias
        @name = options.name
        @only_repo = options.only_repo
        @only_enabled = options.only_enabled
        @only_invalid = options.only_invalid
        @only_protocols = options.only_protocols
        @overrides = options.overrides
        @upgrade_options = { alias: options.alias, name: options.name }
      end

      def filter_options(options)
        {
          only_repo: options[:only_repo].nil? ? @only_repo : options[:only_repo],
          only_enabled: options[:only_enabled].nil? ? @only_enabled : options[:only_enabled],
          only_invalid: options[:only_invalid].nil? ? @only_invalid : options[:only_invalid],
          only_protocols: options[:only_protocols].nil? ? @only_protocols : options[:only_protocols]
        }
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      def next_repo?(repo, num, options)
        (options[:only_repo] && !options[:only_repo].include?(num)) ||
          (options[:only_enabled] && !repo.enabled?) ||
          (options[:only_invalid] && repo.available?) ||
          (options[:only_protocols] && !options[:only_protocols].include?(repo.protocol))
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def group_for_url
        dups = {}
        each_with_number do |repo, num|
          uri = URI.parse(repo.url)
          hostname = uri.hostname.split(".")[-2..-1].join(".")
          idx = URI::HTTP.build(path: uri.path, host: hostname).to_s.gsub(%r{^http://}, "").gsub(%r{/$}, "")
          dups[idx] ||= []
          dups[idx] << { num: num, repo: repo }
        end
        dups
      end

      def select_for_name(str)
        regexp = Regexp.new(str.strip, "i")
        @list.select do |x|
          yield x[:repo], x[:num] if x[:repo].name.match?(regexp) && block_given?
        end
      end

      def select_for_alias(str)
        regexp = Regexp.new(str.gsub("@", "").strip, "i")
        @list.select do |x|
          yield x[:repo], x[:num] if x[:repo].alias.match?(regexp)
        end
      end

      def select_for_url(str)
        regexp = Regexp.new(str.gsub("#", "").strip, "i")
        @list.select do |x|
          yield x[:repo], x[:num] if x[:repo].url.match?(regexp)
        end
      end

      def select_for_any(str)
        regexp = Regexp.new(str.gsub("?", "").strip, "i")
        @list.select do |x|
          yield x[:repo], x[:num] if x[:repo].name.match?(regexp) ||
                                     x[:repo].alias.match?(regexp) ||
                                     x[:repo].url.match?(regexp)
        end
      end

      # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
      def select_repos(repos)
        res = []
        repos.each do |r|
          if r.to_i.positive?
            res.push r.to_i
          elsif r =~ /^\ *@.*/
            select_for_alias(r) { |_, num| res.push num }
          elsif r =~ /^\ *\#.*/
            select_for_url(r) { |_, num| res.push num }
          elsif r =~ /^\ *\?.*/
            select_for_any(r) { |_, num| res.push num }
          else
            puts r
            select_for_name(r) { |_, num| res.push num }
          end
        end

        res.uniq
      end
      # rubocop: enable Metrics/AbcSize, Metrics/MethodLength

      def check_for_override(repo, num, ini)
        raise UnmatchingOverrides, { num: num, ini: ini, repo: repo } if repo.url != ini["old_url"]

        if only_enabled?
          raise MissingOverride, { num: num, ini: ini } unless ini["url"] || ini["enabled"] =~ /no|false|0/i
        else
          raise MissingOverride, { num: num, ini: ini } unless ini["url"]
        end
      end

      def load_overrides(filename)
        raise FileNotFound, filename unless File.exist?(filename)

        ini = IniParse.parse(File.read(filename))
        each_with_number(only_invalid: false) do |repo, num|
          next unless (x = ini["repository_#{num}"])

          repo.enable!(x["enabled"])
          check_for_override(repo, num, x)
          @overrides[num] = x["url"] if x["url"]
        end
      end
    end
    # rubocop: enable Metrics/ClassLength

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

      # rubocop: disable Metrics/AbcSize
      def upgrade!(version, args = {})
        @old_url ||= url
        @old_alias ||= self.alias
        @old_name ||= name

        self.url = (args[:url_override] || url.gsub(/\d\d\.\d/, version))

        self.alias = self.alias.gsub(/\d\d\.\d/, version) if args[:alias]
        self.name = name.gsub(/\d\d\.\d/, version) if args[:name]
      end
      # rubocop: enable Metrics/AbcSize

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
