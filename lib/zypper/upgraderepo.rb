require 'zypper/upgraderepo/repository'
require 'zypper/upgraderepo/request'
require 'zypper/upgraderepo/os_release'
require 'zypper/upgraderepo/utils'
require 'zypper/upgraderepo/view'
require 'zlib'
require 'minitar'


module Zypper
  module Upgraderepo

    class Builder
      def initialize(options)
        @os_release = OsRelease.new(options)
        @repos = RepositoryList.new(options)
        @print_hint = options.hint
        @view_class = Zypper::Upgraderepo::View.const_get options.view.to_s.capitalize

        @overrides = options.overrides
        @upgrade_options = { alias: options.alias, name: options.name }

        @backup_path = options.backup_path
      end

      def backup
        filename = File.join(@backup_path, "repos-backup-#{Time.now.to_s.delete(': +-')[0..-5]}.tgz")

        raise InvalidWritePermissions, filename unless File.writable? @backup_path

        Minitar.pack(RepositoryList::REPOSITORY_PATH, Zlib::GzipWriter.new(File.open(filename, 'wb')))

        Messages.ok "Backup file generated at #{filename.bold.green}"
      end

      def check_current
        check_repos(@os_release.current)
      end

      def check_next
        raise AlreadyUpgraded, 'latest' if @os_release.last?
        @repos.each_with_index { |r, i| r.upgrade(@os_release.next, @upgrade_options.merge(url_override: @overrides[i.next])) }
        check_repos(@os_release.next)
      end

      def check_to
        @repos.each_with_index { |r, i| r.upgrade(@os_release.custom, @upgrade_options.merge(url_override: @overrides[i.next])) }
        check_repos(@os_release.custom)
      end

      def upgrade
        raise AlreadyUpgraded, 'latest' if @os_release.last?
        upgrade_repos(@os_release.next)
      end

      def upgrade_to
        raise AlreadyUpgraded, @os_release.custom if @os_release.current?(@os_release.custom)
        upgrade_repos(@os_release.custom)
      end

      def reset
        upgrade_repos(@os_release.current)
      end

      private

      def check_repos(version)
        @view_class.header(@repos.max_col)

        @repos.each_with_index do |r, i|

          @view_class.separator

          if r.available?
            @view_class.available i.next, r, @repos.max_col
          elsif r.redirected?
            @view_class.redirected i.next, r, @repos.max_col, r.redirected_to
          elsif r.not_found?
            if @print_hint
              @view_class.alternative i.next, r, @repos.max_col, r.evaluate_alternative(version)
            else
              @view_class.not_found i.next, r, @repos.max_col
            end
          elsif r.timeout?
            @view_class.timeout i.next, r, @repos.max_col
          end
        end

        @view_class.footer
      end

      def upgrade_repos(version)
        @view_class.header(@repos.max_col, true)

        @repos.each_with_index do |repo, i|

          @view_class.separator

          repo.upgrade(version, @upgrade_options.merge(url_override: @overrides[i.next]))

          if repo.upgraded?
            @view_class.upgraded i.next, repo, @repos.max_col
          else
            @view_class.untouched i.next, repo, @repos.max_col
          end
        end

        @view_class.separator

        @repos.save
        Messages.ok 'Repositories upgraded!'
      end

    end

  end
end
