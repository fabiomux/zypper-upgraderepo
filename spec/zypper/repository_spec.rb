# frozen_string_literal: true

require "spec_helper"

RSpec.describe Repository do
  before(:all) do
    @repo_files = [
      "repos/packman.repo",
      "repos/oss.repo",
      "repos/non_oss.repo"
    ].map { |x| File.join [Dir.pwd, "spec", x] }

    @repos = @repo_files.map { |r| Repository.new(r) }
  end

  describe "Loading the single repository" do
    it "Reads the name" do
      expect(@repos.map(&:name).sort).to eq([
        "Packman_Leap_15.4",
        "openSUSE_Leap_15.4_OSS",
        "openSUSE_Leap_15.4_non-OSS"
      ].sort)
    end

    it "Reads the alias" do
      expect(@repos.map(&:alias).sort).to eq(%w[
        Packman
        OSS
        non_OSS
      ].sort)
    end

    it "Checks if enabled" do
      expect(@repos.map(&:enabled?)).to eq([
                                             true,
                                             true,
                                             true
                                           ])
    end
  end
end
