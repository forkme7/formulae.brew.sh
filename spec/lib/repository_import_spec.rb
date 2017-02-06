# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2017, Sebastian Staudt

require 'repository_import'

describe RepositoryImport do

  let(:repo) do
    repo = Repository.new name: Repository::MAIN, full: false
    repo.extend subject
  end

  describe '#path' do
    it 'returns the filesystem path of the Git repository' do
      expect(repo.path).to eq("#{Braumeister::Application.tmp_path}/repos/#{Repository::MAIN}")
    end
  end

  describe '#git' do

    context 'can call Git commands' do

      let(:command) { "git --git-dir #{repo.path}/.git log" }

      it 'successfully' do
        repo.expects(:`).with(command).returns 'log output'
        `test 0 -eq 0`

        expect(repo.git('log')).to eq('log output')
      end

      it 'with errors' do
        repo.expects(:`).with(command).returns ''
        `test 0 -eq 1`

        expect(-> { repo.git('log') }).to raise_error(RuntimeError, "Execution of `#{command}` failed.")
      end

    end

  end

  describe '#clone_or_pull' do

    it 'clones a new repository' do
      File.expects(:exists?).with(repo.path).returns false
      repo.expects(:git).with "clone --quiet #{repo.url} #{repo.path}"

      repo.clone_or_pull
    end

    context 'updates an already known repository' do

      it 'and clones it if it doesn\'t exist yet' do
        File.expects(:exists?).with(repo.path).returns false
        repo.expects(:git).with "clone --quiet #{repo.url} #{repo.path}"

        repo.clone_or_pull
      end

      it 'and fetches updates if it already exists' do
        File.expects(:exists?).with(repo.path).returns true
        repo.expects(:git).with('fetch --force --quiet origin master')
        repo.expects(:git).with('diff --shortstat HEAD FETCH_HEAD').returns '1'
        repo.expects(:git).with("--work-tree #{repo.path} reset --hard --quiet FETCH_HEAD")

        repo.clone_or_pull
      end

    end

  end

  describe '#update_status' do

    before do
      repo.expects :clone_or_pull
      repo.expects(:git).with('log -1 --format=format:"%H %ct" HEAD').
        returns 'deadbeef 1325844635'
    end

    it 'can get the current status of a new repository' do
      expect(repo.update_status).to be_nil
    end

    it 'can update the current status of a repository' do
      repo.sha = '01234567'
      Rails.logger.expects(:info).with "Updated #{Repository::MAIN} from 01234567 to deadbeef:"

      expect(repo.update_status).to eq('01234567')

      expect(repo.date).to eq(Time.at 1325844635)
      expect(repo.sha).to eq('deadbeef')
    end

  end

end
