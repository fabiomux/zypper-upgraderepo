# frozen_string_literal: true

require "spec_helper"

class RepositoryListRspec < RepositoryList
  REPOSITORY_PATH = File.join([Dir.pwd, "spec", "repos"])
end

class OsReleaseRspec < OsRelease
  OS_RELEASE_FILE = File.join([Dir.pwd, "spec", "os-release"])
end

RSpec.describe RepositoryList do
  before(:all) do
    @options = CliOptions.new

    @options.operation = :check_current
    @options.backup_path = Dir.home
    @options.only_enabled = false
    @options.alias = true
    @options.name = true
    @options.hint = true
    @options.overrides = {}
    @options.version = nil
    @options.sorting_by = :alias
    @options.view = :table
    @options.only_repo = nil
    @options.timeout = 10.0
    @options.exit_on_fail = false
    @options.overrides_filename = nil
    @options.only_invalid = false
    @options.only_protocols = nil
    @options.allow_unstable = false

    @os_release = OsReleaseRspec.new(@options)

    @repo_list = RepositoryListRspec.new(@options)
  end

  describe "Loading the repositories" do
    it "Returns the repository names" do
      res = []
      @repo_list.each_with_number do |repo, _num|
        res << repo.name
      end

      expect(res.sort).to eq([
        "Packman_Leap_15.4",
        "openSUSE_Leap_15.4_OSS",
        "openSUSE_Leap_15.4_non-OSS",
        "openSUSE_Leap_15.3_debug_non-OSS"
      ].sort)
    end

    it "Returns the repository aliases" do
      res = []
      @repo_list.each_with_number do |repo, _num|
        res << repo.alias
      end

      expect(res.sort).to eq(%w[
        Packman
        OSS
        non_OSS
        Debug_non_OSS
      ].sort)
    end

    it "Checks if repositories are available" do
      res = []
      @repo_list.each_with_number do |repo, _num|
        res << repo.available?
      end

      expect(res).to eq([
                          true,
                          true,
                          true,
                          true
                        ])
    end

    it "Checks for openSUSE Leap 15.4 and detects no invalid repository" do
      res = []
      @repo_list.upgrade!("15.4")
      @repo_list.each_with_number do |repo, _num|
        res << repo.available?
      end

      expect(res.select { |x| x == false }.count).to eq(0)
    end
  end
end
