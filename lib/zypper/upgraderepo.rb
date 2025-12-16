# frozen_string_literal: true

require "zypper/upgraderepo/repository"
require "zypper/upgraderepo/request"
require "zypper/upgraderepo/os_release"
require "zypper/upgraderepo/utils"
require "zypper/upgraderepo/view"
require "zlib"
require "minitar"

module Zypper
  module Upgraderepo
    #
    # Facade class for all the operations.
    #
    class Builder
      def initialize(options)
        @os_release = OsRelease.new(options)
        @repos = RepositoryList.new(options, RepositoryVariables.new(@os_release.current))
        @print_hint = options.hint
        @view_class = Zypper::Upgraderepo::View.const_get options.view.to_s.capitalize

        @backup_path = options.backup_path

        @exit_on_fail = options.exit_on_fail
      end

      def backup
        filename = File.join(@backup_path, "repos-backup-#{Time.now.to_s.delete(": +-")[0..-5]}.tgz")

        raise InvalidWritePermissions, filename unless File.writable? @backup_path

        Minitar.pack(RepositoryList::REPOSITORY_PATH, Zlib::GzipWriter.new(File.open(filename, "wb")))

        Messages.ok "Backup file generated at #{filename.bold.green}"
      end

      def check_current
        @repos.upgrade!(@os_release.current)
        check_repos(@os_release.current)
      end

      def check_next
        raise AlreadyUpgraded, "latest" if @os_release.last?

        @repos.upgrade!(@os_release.next)
        check_repos(@os_release.next)
      end

      def check_for
        @repos.upgrade!(@os_release.custom)
        check_repos(@os_release.custom)
      end

      def check_last
        raise AlreadyUpgraded, "latest" if @os_release.last?

        @repos.upgrade!(@os_release.last)
        check_repos(@os_release.last)
      end

      def duplicates
        dups = {}
        dcount = 0
        @view_class.duplicates_header(@repos.max_col)
        @view_class.separator(@repos.max_col, "=", :yellow)
        @repos.each_with_number do |repo, num|
          uri = URI.parse(repo.url)
          hostname = uri.hostname.split(".")[-2..-1].join(".")
          idx = URI::HTTP.build(path: uri.path, host: hostname).to_s.gsub(%r{^http://}, "").gsub(%r{/$}, "")
          dups[idx] ||= []
          dups[idx] << { num: num, repo: repo }
        end
        dups.each_value do |list|
          next if list.count < 2

          dcount += list.count.pred
          list.each_with_index do |l, i|
            @view_class.duplicates_item(l[:num], i.next, list.count, l[:repo], @repos.max_col)
            @view_class.separator(@repos.max_col) unless i == list.count.pred
          end
          @view_class.separator(@repos.max_col, "=", :yellow)
        end
        @view_class.duplicates_footer(dcount, @repos.list.count)
      end

      def unused
        ucount = 0
        @view_class.unused_header(@repos.max_col)
        @view_class.separator(@repos.max_col)
        @repos.each_with_number do |repo, num|
          packs = `zypper -q pa -i -r #{num} 2>/dev/null|grep "^i"|wc -l`.strip.to_i
          next unless packs.zero?

          ucount += 1
          @view_class.unused_item(num, ucount, repo, @repos.max_col)
          @view_class.separator(@repos.max_col)
        end
        @view_class.unused_footer(ucount, @repos.list.count)
      end

      def upgrade_to_next
        raise AlreadyUpgraded, "latest" if @os_release.last?

        @repos.upgrade!(@os_release.next)
        upgrade_repos(@os_release.next)
      end

      def upgrade_to
        raise AlreadyUpgraded, @os_release.custom if @os_release.current?(@os_release.custom)

        @repos.upgrade!(@os_release.custom)
        upgrade_repos(@os_release.custom)
      end

      def upgrade_to_last
        raise AlreadyUpgraded, "latest" if @os_release.last?

        @repos.upgrade!(@os_release.last)
        upgrade_repos(@os_release.last)
      end

      def reset
        upgrade_repos(@os_release.current)
      end

      def status
        @view_class.status(@os_release)
      end

      def update
        @repos.upgrade!(@os_release.current)
        upgrade_repos(@os_release.current)
      end

      private

      def check_repos(version)
        check_requirements(version)

        @view_class.header(@repos.max_col)

        @repos.each_with_number do |repo, num|
          @view_class.separator @repos.max_col

          if repo.available?
            @view_class.available num, repo, @repos.max_col
          else
            raise UnableToUpgrade, { num: num, repo: repo } if @exit_on_fail

            if repo.redirected?
              @view_class.redirected num, repo, @repos.max_col, repo.redirected_to
            elsif repo.not_found?
              if @print_hint
                @view_class.alternative num, repo, @repos.max_col, repo.evaluate_alternative(version)
              else
                @view_class.not_found num, repo, @repos.max_col
              end
            elsif repo.forbidden?
              @view_class.forbidden num, repo, @repos.max_col
            elsif repo.timeout?
              @view_class.timeout num, repo, @repos.max_col
            else
              @view_class.server_error num, repo, @repos.max_col
            end
          end
        end

        @view_class.footer @repos.max_col
      end

      def upgrade_repos(_version)
        @view_class.header(@repos.max_col, upgrade: true)

        @repos.each_with_number do |repo, num|
          @view_class.separator @repos.max_col

          if repo.upgraded?
            @view_class.upgraded num, repo, @repos.max_col
          else
            @view_class.untouched num, repo, @repos.max_col
          end
        end

        @view_class.separator @repos.max_col

        @repos.save
        Messages.ok "Repositories upgraded!"
      end

      def check_requirements(version)
        return unless @os_release.requires_v2?(version)

        raise UnsupportedV2 unless @os_release.v2?
      end
    end
  end
end
