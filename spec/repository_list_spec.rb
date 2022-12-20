require 'spec_helper.rb'
require 'ostruct'

class RepositoryListRspec < RepositoryList
  REPOSITORY_PATH = File.join([Dir.pwd, 'spec', 'repos'])
end

class OsReleaseRspec < OsRelease
  OS_RELEASE_FILE = File.join([Dir.pwd, 'spec', 'os-release'])
end

RSpec.describe RepositoryList do

  before(:all) do
    @options = OpenStruct.new(
      operation: :check_current,
      backup_path: ENV['HOME'],
      only_enabled: false,
      alias: true,
      name: true,
      hint: true,
      overrides: {},
      version: nil,
      sort_by: :alias,
      view: :table,
      only_repo: nil,
      timeout: 10.0,
      exit_on_fail: false,
      overrides_filename: nil,
      only_invalid: false,
      only_protocols: nil,
      allow_unstable: false
    )
    @os_release = OsReleaseRspec.new(@options)

    @repo_list = RepositoryListRspec.new(@options)
  end

  describe 'Loading the repositories' do

    it 'Returns the repository names' do
      res = []
      @repo_list.each_with_number do |repo, num|
        res << repo.name
      end

      expect(res.sort).to eq([
        'Packman_Leap_15.4',
        'openSUSE_Leap_15.4_OSS',
        'openSUSE_Leap_15.4_non-OSS',
        'openSUSE_Leap_15.3_debug_non-OSS',
      ].sort)
    end

    it 'Returns the repository aliases' do
      res = []
      @repo_list.each_with_number do |repo, num|
        res << repo.alias
      end

      expect(res.sort).to eq([
        'Packman',
        'OSS',
        'non_OSS',
        'Debug_non_OSS',
      ].sort)

    end

    it 'Checks if repositories are available' do
      res = []
      @repo_list.each_with_number do |repo, num|
        res << repo.available?
      end

      expect(res).to eq([
        true,
        true,
        true,
        true,
      ])
    end

    it 'Checks for openSUSE Leap 15.4 and detects one invalid repository' do
      res = []
      @repo_list.upgrade!('15.4')
      @repo_list.each_with_number do |repo, num|
        res << repo.available?
      end

      expect(res.select{|x| x == false}.count).to eq(1)
    end

  end
end
