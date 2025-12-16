# frozen_string_literal: true

require "spec_helper"

def remap_list(field)
  res = []
  repo_list.each_with_number { |repo, _num| res << repo.send(field) }
  res
end

RSpec.describe Zypper::Upgraderepo::RepositoryList do
  let(:repo_list) do
    RepositoryListRspec.new(RSpec.configuration.cli_options, RSpec.configuration.upgraderepo_variables)
  end

  let(:repo_names) { remap_list(:name) }
  let(:repo_aliases) { remap_list(:alias) }
  let(:repo_available) { remap_list(:available?) }

  context "Loading the repositories" do
    it "Returns the repository names" do
      expect(repo_names.sort).to eq(["Packman_Leap_15.4", "openSUSE_Leap_15.4_OSS",
                                     "openSUSE_Leap_15.4_non-OSS", "openSUSE_Leap_15.3_debug_non-OSS"].sort)
    end

    it "Returns the repository aliases" do
      expect(repo_aliases.sort).to eq(%w[Packman OSS non_OSS Debug_non_OSS].sort)
    end

    it "Checks if repositories are available" do
      expect(repo_available).to eq([true, true, true, true])
    end

    it "Checks for openSUSE Leap 15.4 and detects no invalid repository" do
      repo_list.upgrade!("15.4")
      expect(repo_available.select { |x| x == false }.count).to eq(0)
    end
  end
end
