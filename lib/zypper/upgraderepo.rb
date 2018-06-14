require 'zypper/upgraderepo/repository'
require 'zypper/upgraderepo/os_release'
require 'zypper/upgraderepo/utils'


module Zypper
  module Upgraderepo

    class Builder
      def initialize(options)
        @os_release = OsRelease.new(options)
        @repos = RepositoryList.new(options)
        @hint = options.hint
      end

      def backup
        @repos.backup
        Messages.ok 'Repository backup executed!'
      end

      def check_current
        check_repos(@os_release.current)
      end

      def check_next
        @repos.upgrade(@os_release.next) unless @os_release.last?
        check_repos(@os_release.next)
      end

      def check_to
        @repos.upgrade(@os_release.custom)
        check_repos(@os_release.custom)
      end

      def upgrade
        @repos.upgrade(@os_release.next) unless @os_release.last?
        @repos.save
        Messages.ok 'Repositories upgraded!'
      end

      def upgrade_to
        @repos.upgrade(@os_release.custom)
        @repos.save
        Messages.ok 'Repositories upgraded!'
      end


      private

      def check_repos(version)
        Messages.header
        @repos.list.each_with_index do |r, i|
          Messages.separator
          if r.available?
            Messages.available i.next, r.name, r.url
          elsif r.redirected?
            Messages.redirect i.next, r.name, r.url, r.redirected_to
          elsif r.not_found?
            Messages.not_found i.next, r.name, r.url
            Messages.alternatives r.evaluate_alternative(version) if @hint
          end
        end
        Messages.footer
      end

    end

  end
end
