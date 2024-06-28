# frozen_string_literal: true

require "spec_helper"

RSpec.describe RepositoryList do
  before(:all) do
    @repo_list = RepositoryListRspec.new(RSpec.configuration.cli_options, RSpec.configuration.upgraderepo_variables)
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
