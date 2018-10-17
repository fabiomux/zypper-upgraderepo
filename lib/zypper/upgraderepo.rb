require 'zypper/upgraderepo/repository'
require 'zypper/upgraderepo/request'
require 'zypper/upgraderepo/os_release'
require 'zypper/upgraderepo/utils'


module Zypper
  module Upgraderepo

    class Builder
      def initialize(options)
        @os_release = OsRelease.new(options)
        @repos = RepositoryList.new(options)
        @print_hint = options.hint
        @view_class = Object.const_get options.view.to_s.split(' ').map(&:capitalize).insert(0,'Zypper::Upgraderepo::').push('View').join
      end

      def backup
        @repos.backup
        Messages.ok 'Repository backup executed!'
      end

      def check_current
        check_repos(@os_release.current)
      end

      def check_next
        raise AlreadyUpgraded, 'latest' if @os_release.last?
        @repos.upgrade(@os_release.next) 
        check_repos(@os_release.next)
      end

      def check_to
        @repos.upgrade(@os_release.custom)
        check_repos(@os_release.custom)
      end

      def upgrade
        raise AlreadyUpgraded, 'latest' if @os_release.last?
        @repos.upgrade(@os_release.next)
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
        @view_class.header(@repos.max_col)

        @repos.list.each_with_index do |r, i|
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
          end
        end

        @view_class.footer
      end

    end

  end
end
