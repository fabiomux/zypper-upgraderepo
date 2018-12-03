module Zypper
  module Upgraderepo

    module View

      class Report

        def self.available(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.green} | Status: #{'Ok'.bold.green}"
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
          puts " #{num.to_s.rjust(2).bold.green} | #{'Upgraded'.bold.green}" #{'Upgraded from:'.bold.green} #{repo.old_url}"
          #puts " #{' ' * 2} | Old Name: #{old_data[:name].yellow}" if old_data[:name] != repo.name
          #puts " #{' ' * 2} | Old Alias: #{old_data[:alias].yellow}" if old_data[:alias] != repo.alias

          #puts " #{' ' * 2} | Old URL: #{repo.old_url}"
          self.info(repo)
        end

        def self.untouched(num, repo, max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | #{'Untouched'.bold.yellow}"
          self.info(repo)
        end

        def self.separator
          puts '-' * 90
        end

        def self.header(max_col)
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
          Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, ' ')} | #{repo.enabled? ? ' Y ' : ' N '.yellow} |")
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

    end

  end
end
