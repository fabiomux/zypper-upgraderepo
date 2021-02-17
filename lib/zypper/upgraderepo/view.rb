module Zypper
  module Upgraderepo

    module View

      class Report

        def self.available(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.green} | Status: #{'Ok'.bold.green}"
          puts " #{' ' * 2} | Hint: Unversioned repository" if repo.unversioned? && repo.old_url
          self.info(repo)
        end

        def self.redirected(num, repo, max_col, redirected)
          puts " #{num.to_s.rjust(2).bold.yellow} | Status: #{'Redirected'.bold.yellow}"
          puts " #{' ' * 2} | #{'To:'.bold.yellow} #{redirected}"
          self.info(repo)
        end

        def self.not_found(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.red} | Status: #{'Not Found'.bold.red}"
          self.info(repo)
        end

        def self.alternative(num, repo, max_col, alt)
          puts " #{num.to_s.rjust(2).bold.red} | Status: #{'Not Found'.bold.red}"
          puts " #{' ' * 2} | Hint: #{alt[:message].bold.yellow}"
          puts " #{' ' * 2} | #{'Suggested:'.bold.yellow} #{alt[:url]}" unless alt[:url].to_s.empty?
          self.info(repo)
        end

        def self.timeout(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | Status: #{'Server Timeout'.bold.yellow}"
          self.info(repo)
        end

        def self.upgraded(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.green} | #{'Upgraded'.bold.green}"
          self.info(repo)
        end

        def self.untouched(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | #{'Untouched'.bold.yellow}"
          self.info(repo)
        end

        def self.separator
          puts '-' * 90
        end

        def self.header(max_col, upgrade = false)
          puts "  # | Report"
        end

        def self.footer
          self.separator
        end


        private

        def self.info(repo)
          puts " #{ ' ' * 2 } | Name: #{repo.name} #{repo.upgraded?(:name) ? '(' + repo.old_name.yellow + ')' : '' }"
          puts " #{ ' ' * 2 } | Alias: #{repo.alias} #{repo.upgraded?(:alias) ? '(' + repo.old_alias.yellow + ')' : ''}"
          puts " #{ ' ' * 2 } | Url: #{repo.url}"
          puts " #{ ' ' * 2 } |      (#{repo.old_url.yellow})" if repo.upgraded?
          puts " #{ ' ' * 2 } | Priority: #{repo.priority}"
          puts " #{ ' ' * 2 } | #{repo.enabled? ? 'Enabled: Yes' : 'Enabled: No'.yellow}"
          puts " #{ ' ' * 2 } | Filename: #{repo.filename}"
        end
      end


      class Table

        def self.available(num, repo, max_col)
          if repo.unversioned? && repo.old_url
            Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | Unversioned repository")
          else
            Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} |")
          end
        end

        def self.redirected(num, repo, max_col, redirected)
          Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{'Redirection'.bold.yellow} of #{repo.url} ")
          puts " #{' ' * 3} | #{' ' * 2} | #{ ' ' * max_col} | #{ ' ' * 3 } | #{'To:'.bold.yellow} #{redirected}"
        end

        def self.not_found(num, repo, max_col)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} |")
        end

        def self.alternative(num, repo, max_col, alt)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{alt[:message].bold.yellow}")
          puts " #{' ' * 3} | #{' ' * 2} | #{' ' * max_col} | #{' ' * 3} | #{alt[:url]}" unless alt[:url].to_s.empty?
        end

        def self.timeout(num, repo, max_col)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{'Server Timeout'.bold.yellow}")
        end

        def self.upgraded(num, repo, max_col) #, old_data)
          Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{'From:'.bold.green} #{repo.old_url}")
          puts " #{' ' * 3} | #{' ' * 2} | #{' ' * max_col} | #{' ' * 3} | #{'To:'.bold.green} #{repo.url}"
        end

        def self.untouched(num, repo, max_col)
          Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} | #{'Untouched:'.bold.yellow} #{repo.old_url}")
        end

        def self.separator
          puts '-' * 90
        end

        def self.header(max_col, upgrade = false)
          puts " St. |  # | #{'Name'.ljust(max_col, ' ')} | En. | #{upgrade ? 'Details' : 'Hint' }"
        end

        def self.footer
          self.separator
        end
      end


      class Quiet

        def self.available(num, repo, max_col)
        end

        def self.redirected(num, repo, max_col, redirected)
        end

        def self.not_found(num, repo, max_col)
        end

        def self.alternative(num, repo, max_col, alt)
        end

        def self.timeout(num, repo, max_col)
        end

        def self.upgraded(num, repo, max_col) #, old_data)
        end

        def self.untouched(num, repo, max_col)
        end

        def self.separator
        end

        def self.header(max_col, upgrade = false)
        end

        def self.footer
        end

      end


      class Ini

        def self.available(num, repo, max_col)
          self.info num, 'Ok', repo
        end

        def self.redirected(num, repo, max_col, redirected)
          self.info num, 'Redirected', repo, false
          puts "redirected_to=#{redirected}"
        end

        def self.not_found(num, repo, max_col)
          self.info num, 'Not Found', repo, false
        end

        def self.alternative(num, repo, max_col, alt)
          self.info num, 'Not Found', repo, false
          puts "hint=#{alt[:message]}"
          puts "suggested_url=#{alt[:url]}" unless alt[:url].to_s.empty?
        end

        def self.timeout(num, repo, max_col)
          self.info num, 'Server Timeout', repo, false
        end

        def self.upgraded(num, repo, max_col)
          self.info num, 'Upgraded', repo
        end

        def self.untouched(num, repo, max_col)
          self.info num, 'Untouched', repo
        end

        def self.separator
          puts ''
        end

        def self.header(max_col, upgrade = false)
        end

        def self.footer
        end


        private

        def self.info(num, status, repo, valid = true)
          @@number = num
          puts "[repository_#{num}]"
          puts "name=#{repo.name}"
          puts "alias=#{repo.alias}"
          puts "old_url=#{repo.old_url}"
          if valid
            if repo.unversioned? && repo.old_url
              puts <<-'HEADER'.gsub(/^ +/, '')
                # The repository is unversioned: its packages should be perfectly
                # working regardless the distribution version, that because all the
                # required dependencies are included in the repository itself and
                # automatically picked up.
              HEADER
            end
            puts "url=#{repo.url}"
          elsif repo.enabled?
            puts <<-'HEADER'.gsub(/^ +/, '')
              # The interpolated URL is invalid, try overriding with the one suggested
              # in the fields below or find it manually starting from the old_url.
              # The alternatives are:
              # 1. Waiting for a repository upgrade;
              # 2. Change the provider for the related installed packages;
              # 3. Disable the repository putting the enabled status to 'No'.
              #
              url=
            HEADER
          else
            puts <<-'HEADER'.gsub(/^ +/, '')
              # The interpolated URL is invalid, but being the repository disabled you can
              # keep the old_url in the field below, it will be ignored anyway during the
              # normal update and upgrade process.
            HEADER
            puts "url=#{repo.old_url}"
          end
          puts "priority=#{repo.priority}"
          puts "enabled=#{repo.enabled? ? 'Yes' : 'No'}"
          puts "status=#{status}"
        end
      end

    end
  end
end
