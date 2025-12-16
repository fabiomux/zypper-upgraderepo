# frozen_string_literal: true

require "spec_helper"

def remap_list(field)
  res = []
  repo_list.each_with_number { |repo, _num| res << repo.send(field) }
  res
end

RSpec.describe Zypper::Upgraderepo::Repository do
  let(:repo_files) do
    [
      "repos/packman.repo",
      "repos/oss.repo",
      "repos/non_oss.repo"
    ].map { |x| File.join [Dir.pwd, "spec", x] }
  end

  let(:repos) { repo_files.map { |r| Repository.new(r, RSpec.configuration.upgraderepo_variables) } }

  context "Loading the single repository" do
    it "Reads the name" do
      expect(repos.map(&:name).sort).to eq([
        "Packman_Leap_15.4",
        "openSUSE_Leap_15.4_OSS",
        "openSUSE_Leap_15.4_non-OSS"
      ].sort)
    end

    it "Reads the alias" do
      expect(repos.map(&:alias).sort).to eq(%w[Packman OSS non_OSS].sort)
    end

    it "Checks if enabled" do
      expect(repos.map(&:enabled?)).to eq([true, true, true])
    end
  end
end
