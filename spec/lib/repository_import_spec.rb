# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2015, Sebastian Staudt

require 'repository_import'

describe RepositoryImport do

  let(:repo) do
    repo = Repository.new name: Repository::MAIN, full: true,
                          special_formula_regex: nil
    repo.extend subject
  end

  before do
    Repository.stubs(:find).with(Repository::MAIN).returns repo
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

    it 'clones or updates the main repository for non-full repositories' do
      main_repo = repo
      main_repo.expects :clone_or_pull

      tap_repo = repo.dup
      tap_repo.extend RepositoryImport
      tap_repo.full = false
      File.expects(:exists?).with(tap_repo.path).returns false
      tap_repo.expects(:git).with "clone --quiet #{repo.url} #{repo.path}"

      tap_repo.clone_or_pull
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

  describe '#generate_history!' do
    it 'resets the repository and generates the history from scratch' do
      repo.revisions << Revision.new(sha: '01234567')
      repo.revisions << Revision.new(sha: 'deadbeef')
      repo.formulae << Formula.new(name: 'bazaar', revisions: repo.revisions)
      repo.formulae << Formula.new(name: 'git', revisions: repo.revisions)
      repo.authors << Author.new(name: 'Sebastian Staudt')

      repo.expects :update_status
      repo.expects :generate_history

      repo.generate_history!

      expect(repo.revisions).to be_empty
      expect(repo.authors).to be_empty
      repo.formulae.each { |formula| expect(formula.revisions).to be_empty }
    end
  end

  describe '#refresh' do
    it 'does nothing when nothing has changed' do
      repo.expects(:update_status).returns [[], [], 'deadbeef']
      Rails.logger.expects(:info).with 'No formulae changed.'
      repo.expects(:generate_history).never
      repo.stubs :save!

      repo.refresh
    end
  end

  describe '#formulae_info' do

    before do
      class FormulaSpecificationError; end
      class FormulaUnavailableError; end
      class FormulaValidationError; end
      class Formulary
        class FormulaLoader; end

        def self.repositories=(repositories); end
      end

      def repo.fork
        yield
        1234
      end

      Process.expects(:wait).with 1234

      repo.expects(:require).with 'sandbox_backtick'
      repo.expects(:require).with 'sandbox_io_popen'
      Object.expects(:remove_const).with :Formula
      repo.expects(:require).with 'Library/Homebrew/global'
      repo.expects(:require).with 'Library/Homebrew/formula'
      repo.expects(:require).with 'Library/Homebrew/os/mac'
      repo.expects(:require).with 'sandbox_argv'
      repo.expects(:require).with 'sandbox_formulary'
      repo.expects(:require).with 'sandbox_macos'
      repo.expects(:require).with 'sandbox_utils'
    end

    it 'sets some global information on the repo path' do
      repo.expects(:path).returns 'path'
      $LOAD_PATH.expects(:unshift).with File.join('path')
      $LOAD_PATH.expects(:unshift).with File.join('path', 'Library', 'Homebrew')

      repo.send :formulae_info, []

      expect($homebrew_path).to eq('path')
    end

    it 'uses a forked process to load formula information' do
      git = mock deps: [], desc: 'Distributed revision control system', homepage: 'http://git-scm.com', keg_only?: false, name: 'git', stable: mock(version: '1.7.9'), devel: nil, head: mock(version: 'HEAD')
      git_loader = mock get_formula: git
      memcached = mock deps: %w(libevent), desc: 'High performance, distributed memory object caching system', homepage: 'http://memcached.org/', keg_only?: false, name: 'memcached', stable: mock(version: '1.4.11'), devel: mock(version: '2.0.0.dev') , head: nil
      memcached_loader = mock get_formula: memcached

      Formula.expects(:class_s).with('git').returns :Git
      Formula.expects(:path).with('git').returns '/path/to/git'
      Formulary::FormulaLoader.expects(:new).with('git', '/path/to/git').returns git_loader
      Formula.expects(:class_s).with('memcached').returns :Memcached
      Formula.expects(:path).with('memcached').returns '/path/to/memcached'
      Formulary::FormulaLoader.expects(:new).with('memcached', '/path/to/memcached').returns memcached_loader

      formulae_info = repo.send :formulae_info, %w{git memcached}
      expect(formulae_info).to eq({
        'git' => { deps: [], description: 'Distributed revision control system', homepage: 'http://git-scm.com', keg_only: false, stable_version: '1.7.9', devel_version: nil, head_version:'HEAD' },
        'memcached' => { deps: %w(libevent), description: 'High performance, distributed memory object caching system', homepage: 'http://memcached.org/', keg_only: false, stable_version: '1.4.11', devel_version: '2.0.0.dev', head_version: nil }
      })
    end

    it 'reraises errors caused by the subprocess' do
      Formula.expects(:class_s).with('git').raises StandardError.new('subprocess failed')

      expect(-> { repo.send :formulae_info, %w{git} }).to raise_error(StandardError, 'subprocess failed')
    end

  end

  describe '#formula_regex' do

    let :repo do
      repo = Repository.new
      repo.extend subject
    end

    it 'returns a specific regex for full repos' do
      repo.full = true
      expect(repo.formula_regex).to eq(/^(?:Library\/)?Formula\/(.+?)\.rb$/)
    end

    it 'returns a generic regex for other repos' do
      expect(repo.formula_regex).to eq(/^(.+?\.rb)$/)
    end

    it 'returns the special regex if one is defined' do
      repo.special_formula_regex = '.*'
      expect(repo.formula_regex).to eq(/.*/)
    end

  end

  describe '#update_status' do

    before do
      repo.expects :clone_or_pull
      repo.expects(:git).with('log -1 --format=format:"%H %ct" HEAD').
        returns 'deadbeef 1325844635'
    end

    it 'can get the current status of a new full repository' do
      repo.expects(:git).with('ls-tree --name-only HEAD Library/Formula/').
        returns "Library/Formula/bazaar.rb\nLibrary/Formula/git.rb\nLibrary/Formula/mercurial.rb"
      repo.expects(:git).with('ls-tree --name-only HEAD Library/Aliases/').
        returns "Library/Aliases/bzr\nLibrary/Aliases/hg"

      formulae, aliases, last_sha = repo.update_status

      expect(formulae).to eq([%w{A Library/Formula/bazaar.rb}, %w{A Library/Formula/git.rb}, %w{A Library/Formula/mercurial.rb}])
      expect(aliases).to eq([%w{A Library/Aliases/bzr}, %w{A Library/Aliases/hg}])
      expect(last_sha).to be_nil
    end

    it 'can get the current status of a new tap repository' do
      repo.full = false
      repo.expects(:git).with('ls-tree --name-only -r HEAD').
        returns "bazaar.rb\ngit.rb\nmercurial.rb"

      formulae, aliases, last_sha = repo.update_status

      expect(formulae).to eq([%w{A bazaar.rb}, %w{A git.rb}, %w{A mercurial.rb}])
      expect(aliases).to eq([])
      expect(last_sha).to be_nil
    end

    it 'can update the current status of a repository' do
      repo.sha = '01234567'
      repo.expects(:git).with('diff --name-status 01234567..HEAD').
        returns "D\tLibrary/Aliases/bzr\nA\tLibrary/Aliases/hg\nD\tLibrary/Formula/bazaar.rb\nM\tLibrary/Formula/git.rb\nA\tLibrary/Formula/mercurial.rb"
      Rails.logger.expects(:info).with "Updated #{Repository::MAIN} from 01234567 to deadbeef:"

      formulae, aliases, last_sha = repo.update_status

      expect(formulae).to eq([%w{D Library/Formula/bazaar.rb}, %w{M Library/Formula/git.rb}, %w{A Library/Formula/mercurial.rb}])
      expect(aliases).to eq([%w{D Library/Aliases/bzr}, %w{A Library/Aliases/hg}])
      expect(last_sha).to eq('01234567')
    end

    after do
      expect(repo.date).to eq(Time.at 1325844635)
      expect(repo.sha).to eq('deadbeef')
    end

  end

end
