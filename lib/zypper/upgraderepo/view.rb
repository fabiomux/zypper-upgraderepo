# frozen_string_literal: true

module Zypper
  module Upgraderepo
    module View
      #
      # Report style output.
      #
      class Report
        def self.available(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.green} | Status: #{"Ok".bold.green}"
          puts " #{" " * 2} | Hint: Unversioned repository" if repo.unversioned? && repo.old_url
          info(repo)
        end

        def self.redirected(num, repo, _max_col, redirected)
          puts " #{num.to_s.rjust(2).bold.yellow} | Status: #{"Redirected".bold.yellow}"
          puts " #{" " * 2} | #{"To:".bold.yellow} #{redirected}"
          info(repo)
        end

        def self.not_found(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.red} | Status: #{"Not Found".bold.red}"
          info(repo)
        end

        def self.forbidden(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.red} | Status: #{"Forbidden Path".bold.red}"
          info(repo)
        end

        def self.alternative(num, repo, _max_col, alt)
          puts " #{num.to_s.rjust(2).bold.red} | Status: #{"Not Found".bold.red}"
          puts " #{" " * 2} | Hint: #{alt[:message].bold.yellow}"
          puts " #{" " * 2} | #{"Suggested:".bold.yellow} #{alt[:url]}" unless alt[:url].to_s.empty?
          info(repo)
        end

        def self.timeout(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | Status: #{"Server Timeout".bold.yellow}"
          info(repo)
        end

        def self.upgraded(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.green} | #{"Upgraded".bold.green}"
          info(repo)
        end

        def self.untouched(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | #{"Untouched".bold.yellow}"
          info(repo)
        end

        def self.server_error(num, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.red} | Status: #{"Server Error".bold.red}"
          puts " #{" " * 2} | Hint: #{repo.status}"
          info(repo)
        end

        def self.separator(max_col, char = "-", color = :none)
          puts (char * (max_col + 20)).send(color)
        end

        def self.header(*)
          puts "  # | Report"
        end

        def self.footer(max_col)
          separator max_col
        end

        def self.status(os_release)
          color = os_release.seniority.zero? ? :green : :yellow
          puts "----------------------------------------------"
          puts "Full name       | #{os_release.fullname.bold}"
          puts "----------------------------------------------"
          puts "Current release | #{os_release.current.send(color)}"
          puts "Next release    | #{os_release.seniority.positive? ? os_release.next.bold.green : "-"}"
          puts "Last release    | #{os_release.last.send(os_release.unstable ? :red : :clean)} " \
               "(#{os_release.unstable ? "Unstable".bold.red : "Stable".bold.green})"
          puts "Available       | #{os_release.seniority.positive? ? os_release.newer.map(&:bold).join(", ") : "-"}"
          puts "----------------------------------------------"
        end

        def self.info(repo)
          old_name = repo.upgraded?(:name) ? "(#{repo.old_name.yellow})" : ""
          old_alias = repo.upgraded?(:alias) ? "(#{repo.old_alias.yellow})" : ""

          puts " #{" " * 2} | Name: #{repo.name} #{old_name}"
          puts " #{" " * 2} | Alias: #{repo.alias} #{old_alias}"
          puts " #{" " * 2} | Url: #{repo.url}"
          puts " #{" " * 2} |      (#{repo.old_url.yellow})" if repo.upgraded?
          puts " #{" " * 2} | Priority: #{repo.priority}"
          puts " #{" " * 2} | #{repo.enabled? ? "Enabled: Yes" : "Enabled: No".yellow}"
          puts " #{" " * 2} | Filename: #{repo.filename}"
        end

        def self.duplicates_header(_max_col)
          puts "  # | Duplicated repositories"
        end

        def self.duplicates_item(num, dnum, dcount, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | Duplicated repository n.#{dnum.to_s.bold}/#{dcount.to_s.bold}"
          info(repo)
        end

        def self.duplicates_footer(dcount, total)
          puts "Total duplicated repositories: #{dcount.to_s.bold.yellow}/#{total}"
        end

        def self.unused_header(_max_col)
          puts "  # | Unused repositories"
        end

        def self.unused_item(num, unum, repo, _max_col)
          puts " #{num.to_s.rjust(2).bold.yellow} | Unused repository n.#{unum.to_s.bold}"
          info(repo)
        end

        def self.unused_footer(ucount, total)
          puts "Total unused repositories: #{ucount.to_s.bold.yellow}/#{total}"
        end
      end

      #
      # Table style output.
      #
      class Table
        def self.available(num, repo, max_col)
          if repo.unversioned? && repo.old_url
            Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                        "| #{repo.enabled? ? " Y " : " N ".yellow} | Unversioned repository")
          else
            Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                        "| #{repo.enabled? ? " Y " : " N ".yellow} |")
          end
        end

        def self.redirected(num, repo, max_col, redirected)
          Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                           "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"Redirection".bold.yellow} of #{repo.url} ")
          puts " #{" " * 3} | #{" " * 2} | #{" " * max_col} | #{" " * 3} | #{"To:".bold.yellow} #{redirected}"
        end

        def self.not_found(num, repo, max_col)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                         "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"Not Found".bold.red}")
        end

        def self.forbidden(num, repo, max_col)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                         "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"Forbidden path".bold.red}")
        end

        def self.alternative(num, repo, max_col, alt)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                         "| #{repo.enabled? ? " Y " : " N ".yellow} | #{alt[:message].bold.yellow}")
          puts " #{" " * 3} | #{" " * 2} | #{" " * max_col} | #{" " * 3} | #{alt[:url]}" unless alt[:url].to_s.empty?
        end

        def self.timeout(num, repo, max_col)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                         "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"Server Timeout".bold.yellow}")
        end

        def self.upgraded(num, repo, max_col)
          Messages.ok("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                      "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"From:".bold.green} #{repo.old_url}")
          puts " #{" " * 3} | #{" " * 2} | #{" " * max_col} | #{" " * 3} | #{"To:".bold.green} #{repo.url}"
        end

        def self.untouched(num, repo, max_col)
          Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                           "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"Untouched:".bold.yellow} #{repo.old_url}")
        end

        def self.server_error(num, repo, max_col)
          Messages.error("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                         "| #{repo.enabled? ? " Y " : " N ".yellow} | #{"Error:".bold.red} #{repo.status}")
        end

        def self.separator(max_col, char = "-", color = :none)
          puts (char * (max_col + 20)).send(color)
        end

        def self.header(max_col, upgrade: false)
          puts " St. |  # | #{"Name".ljust(max_col, " ")} | En. | #{upgrade ? "Details" : "Hint"}"
        end

        def self.footer(max_col)
          separator max_col
        end

        def self.status(os_release)
          puts "---------------------------------------------------"
          puts " System releases based on #{os_release.fullname.bold}"
          puts "---------------------------------------------------"
          puts " Current |  Next  |  Last  | Available"
          puts "--------------------------------------------------"
          puts "   #{os_release.current}  " \
               "|  #{os_release.seniority.positive? ? os_release.next.bold.green : " -  "}  " \
               "|  #{os_release.last.send(os_release.unstable ? :red : :clean)}  " \
               "| #{os_release.seniority.positive? ? os_release.newer.join(", ") : "-"}"
          puts "--------------------------------------------------"
          return unless os_release.unstable

          Messages.warning "The #{"last".bold.red} version should be considered #{"Unstable".bold.red}"
        end

        def self.duplicates_header(max_col)
          puts " St. |  # | #{"Name".ljust(max_col, " ")} | En. | Details"
        end

        def self.duplicates_item(num, dnum, dcount, repo, max_col)
          Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                           "| #{repo.enabled? ? " Y " : " N ".yellow} " \
                           "| Duplicate n.#{dnum.to_s.bold}/#{dcount.to_s.bold} ")
        end

        def self.duplicates_footer(dcount, total)
          puts "Total duplicated repositories: #{dcount.to_s.bold.yellow}/#{total}"
        end

        def self.unused_header(max_col)
          puts " St. |  # | #{"Name".ljust(max_col, " ")} | En. | Details"
        end

        def self.unused_item(num, unum, repo, max_col)
          Messages.warning("| #{num.to_s.rjust(2)} | #{repo.name.ljust(max_col, " ")} " \
                           "| #{repo.enabled? ? " Y " : " N ".yellow} " \
                           "| Unused n.#{unum.to_s.bold}")
        end

        def self.unused_footer(ucount, total)
          puts "Total unused repositories: #{ucount.to_s.bold.yellow}/#{total}"
        end
      end

      #
      # Quiet style output.
      #
      class Quiet
        def self.available(num, repo, max_col); end

        def self.redirected(num, repo, max_col, redirected); end

        def self.not_found(num, repo, max_col); end

        def self.forbidden(num, repo, max_col); end

        def self.alternative(num, repo, max_col, alt); end

        def self.timeout(num, repo, max_col); end

        def self.upgraded(num, repo, max_col); end

        def self.untouched(num, repo, max_col); end

        def self.server_error(num, repo, max_col); end

        def self.separator(_max_col, _char = "-", _color = :none); end

        def self.header(max_col, upgrade: false); end

        def self.footer(_max_col); end

        def self.status(os_release)
          puts "#{os_release.seniority} #{os_release.newer.join(" ")}"
        end

        def self.duplicates_header(_max_col); end

        def self.duplicates_item(num, dnum, _dcount, _repo, _max_col)
          puts "#{dnum}:#{num} "
        end

        def self.duplicates_footer(dcount, total); end

        def self.unused_header(_max_col); end

        def self.unused_item(num, _unum, _repo, _max_col)
          puts num
        end

        def self.unused_footer(ucount, total); end
      end

      #
      # Ini style output.
      #
      class Ini
        def self.available(num, repo, _max_col)
          info num, "Ok", repo
        end

        def self.redirected(num, repo, _max_col, redirected)
          info num, "Redirected", repo, false
          puts "redirected_to=#{redirected}"
        end

        def self.not_found(num, repo, _max_col)
          info num, "Not Found", repo, valid: false
        end

        def self.forbidden(num, repo, _max_col)
          info num, "Forbidden Path", repo, valid: false
        end

        def self.alternative(num, repo, _max_col, alt)
          info num, "Not Found", repo, valid: false, suggested: alt[:url]
          puts "hint=#{alt[:message]}"
          puts "suggested_url=#{alt[:url]}" unless alt[:url].to_s.empty?
        end

        def self.timeout(num, repo, _max_col)
          info num, "Server Timeout", repo, valid: false
        end

        def self.upgraded(num, repo, _max_col)
          info num, "Upgraded", repo
        end

        def self.untouched(num, repo, _max_col)
          info num, "Untouched", repo
        end

        def self.server_error(num, repo, _max_col)
          info num, "Server Error", repo
          puts "error=#{repo.status}"
        end

        def self.separator(_max_col, _char = "-", _color = :none)
          puts ""
        end

        def self.header(max_col, upgrade: false); end

        def self.footer(_max_col); end

        def self.status(os_release)
          puts "[os_release]"
          puts "name=#{os_release.fullname}"
          puts "current=#{os_release.current}"
          puts "next=#{os_release.next}"
          puts "last=#{os_release.last}"
          puts "available=#{os_release.newer.join(" ")}"
          puts "allow_unstable=#{os_release.unstable}"
        end

        def self.info(num, status, repo, valid: true, suggested: "")
          puts "[repository_#{num}]"
          puts "name=#{repo.name}"
          puts "alias=#{repo.alias}"
          puts "old_url=#{repo.old_url}" if repo.upgraded? || !suggested.empty?
          if valid
            if repo.unversioned? && repo.old_url
              puts <<-HEADER.gsub(/^ +/, "")
                # The repository is unversioned: its packages should be perfectly
                # working regardless the distribution version, that because all the
                # required dependencies are included in the repository itself and
                # automatically picked up.
              HEADER
            end
            puts "url=#{repo.url}"
          elsif repo.enabled?
            puts <<-HEADER.gsub(/^ +/, "")
              # The interpolated URL is invalid, try overriding with the one suggested
              # in the field below or find it manually starting from the old_url.
              # The alternatives are:
              # 1. Waiting for a repository upgrade;
              # 2. Change the provider for the related installed packages;
              # 3. Disable the repository putting the enabled status to 'No'.
              #
              url=
            HEADER
          else
            puts <<-HEADER.gsub(/^ +/, "")
              # The interpolated URL is invalid, but being the repository disabled you can
              # keep the old_url in the field below, it will be ignored anyway during the
              # normal update and upgrade process.
            HEADER
            puts "url=#{repo.old_url}"
          end
          puts "priority=#{repo.priority}"
          puts "enabled=#{repo.enabled? ? "Yes" : "No"}"
          puts "status=#{status}"
        end

        def self.duplicates_header(_max_col); end

        def self.duplicates_item(num, dnum, dcount, repo, _max_col)
          puts "[repository_#{num}]" if dnum == 1
          puts "number_#{dnum}_#{dcount}=#{num}"
          puts "name_#{dnum}_#{dcount}=#{repo.name}"
          puts "alias_#{dnum}_#{dcount}=#{repo.alias}"
          puts "url_#{dnum}_#{dcount}=#{repo.url}"
          puts "priority_#{dnum}_#{dcount}=#{repo.priority}"
          puts "enabled_#{dnum}_#{dcount}=#{repo.enabled? ? "Yes" : "No"}"
        end

        def self.duplicates_footer(dcount, total); end

        def self.unused_header(_max_col); end

        def self.unused_item(num, _unum, repo, _max_col)
          puts "[repository_#{num}]"
          puts "number=#{num}"
          puts "name=#{repo.name}"
          puts "alias=#{repo.alias}"
          puts "url=#{repo.url}"
          puts "priority=#{repo.priority}"
          puts "enabled=#{repo.enabled? ? "Yes" : "No"}"
        end

        def self.unused_footer(ucount, total); end
      end

      #
      # Ini style output with inferred solution.
      #
      class Solved < Ini
        def self.alternative(num, repo, _max_col, alt)
          info num, "Not Found", repo, valid: false, suggested: alt[:url]
          puts "hint=#{alt[:message]}"
          puts "suggested_url=#{alt[:url]}" unless alt[:url].to_s.empty?
        end

        def self.info(num, status, repo, valid: true, suggested: "")
          puts "[repository_#{num}]"
          puts "name=#{repo.name}"
          puts "alias=#{repo.alias}"
          puts "old_url=#{repo.old_url}" if repo.upgraded? || !suggested.empty?
          if valid
            if repo.unversioned? && repo.old_url
              puts <<-HEADER.gsub(/^ +/, "")
                # The repository is unversioned: its packages should be perfectly
                # working regardless the distribution version, that because all the
                # required dependencies are included in the repository itself and
                # automatically picked up.
              HEADER
            end
            puts "url=#{repo.url}"
          elsif repo.enabled?
            if suggested.empty?
              puts <<-HEADER.gsub(/^ +/, "")
                # The interpolated URL is invalid, and the script has not been able to find
                # an alternative. The best thing to do here is to disable the repository.
                # In case a valid alternative will be discovered, just replace its URL in
                # the "url" field below and make sure to re-enable the repository by switching
                # the "enabled" field to "Yes" again.
                #
              HEADER
              puts "url=#{repo.old_url}"
              puts "enabled=No"
            else
              puts <<-HEADER.gsub(/^ +/, "")
                # The interpolated URL is invalid, but the script found an alternative
                # URL which will be used to override the old value.
                # Unfortunately the script is not able to know if the found URL is exact,
                # so review the result before accepting any change, and in case want
                # to disable it, just turn the "enabled" field below to "No".
                #
              HEADER
              puts "url=#{suggested}"
              puts "enabled=Yes"
            end
          else
            puts <<-HEADER.gsub(/^ +/, "")
              # The interpolated URL is invalid, but being the repository disabled you can
              # keep the old_url in the field below, it will be ignored anyway during the
              # system update and the upgrade process until the repository is enabled again.
            HEADER
            puts "url=#{suggested.empty? ? repo.old_url : suggested}"
          end
          puts "priority=#{repo.priority}"
          puts "status=#{status}"
        end
      end
    end
  end
end
