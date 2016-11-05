# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2016, Sebastian Staudt

require 'repository_import'

describe RepositoryImport do

  let(:core_repo) do
    repo = Repository.new name: Repository::CORE, full: false,
                          special_formula_regex: nil
    repo.extend subject
  end

  let(:main_repo) do
    repo = Repository.new name: Repository::MAIN, full: true,
                          special_formula_regex: nil
    repo.extend subject
  end

  before do
    Repository.stubs(:find).with(Repository::CORE).returns core_repo
    Repository.stubs(:find).with(Repository::MAIN).returns main_repo
    Repository.stubs(:main).returns main_repo
  end

  describe '#path' do
    it 'returns the filesystem path of the Git repository' do
      expect(core_repo.path).to eq("#{Braumeister::Application.tmp_path}/repos/#{Repository::CORE}")
      expect(main_repo.path).to eq("#{Braumeister::Application.tmp_path}/repos/#{Repository::MAIN}")
    end
  end

  describe '#git' do

    context 'can call Git commands' do

      let(:command) { "git --git-dir #{core_repo.path}/.git log" }

      it 'successfully' do
        core_repo.expects(:`).with(command).returns 'log output'
        `test 0 -eq 0`

        expect(core_repo.git('log')).to eq('log output')
      end

      it 'with errors' do
        core_repo.expects(:`).with(command).returns ''
        `test 0 -eq 1`

        expect(-> { core_repo.git('log') }).to raise_error(RuntimeError, "Execution of `#{command}` failed.")
      end

    end

  end

  describe '#clone_or_pull' do

    it 'clones a new repository' do
      File.expects(:exists?).with(main_repo.path).returns false
      main_repo.expects(:git).with "clone --quiet #{main_repo.url} #{main_repo.path}"

      main_repo.clone_or_pull
    end

    it 'clones or updates the main repository for non-full repositories' do
      main_repo.expects :clone_or_pull

      File.expects(:exists?).with(core_repo.path).returns false
      core_repo.expects(:git).with "clone --quiet #{core_repo.url} #{core_repo.path}"

      core_repo.clone_or_pull
    end

    context 'updates an already known repository' do

      before do
        main_repo.expects :clone_or_pull
      end

      it 'and clones it if it doesn\'t exist yet' do
        File.expects(:exists?).with(core_repo.path).returns false
        core_repo.expects(:git).with "clone --quiet #{core_repo.url} #{core_repo.path}"

        core_repo.clone_or_pull
      end

      it 'and fetches updates if it already exists' do
        File.expects(:exists?).with(core_repo.path).returns true
        core_repo.expects(:git).with('fetch --force --quiet origin master')
        core_repo.expects(:git).with('diff --shortstat HEAD FETCH_HEAD').returns '1'
        core_repo.expects(:git).with("--work-tree #{core_repo.path} reset --hard --quiet FETCH_HEAD")

        core_repo.clone_or_pull
      end

    end

  end

  describe '#generate_history!' do
    it 'resets the repository and generates the history from scratch' do
      core_repo.revisions << Revision.new(sha: '01234567')
      core_repo.revisions << Revision.new(sha: 'deadbeef')
      core_repo.formulae << Formula.new(name: 'bazaar', revisions: core_repo.revisions)
      core_repo.formulae << Formula.new(name: 'git', revisions: core_repo.revisions)
      core_repo.authors << Author.new(name: 'Sebastian Staudt')

      core_repo.expects :update_status
      core_repo.expects :generate_history

      core_repo.generate_history!

      expect(core_repo.revisions).to be_empty
      expect(core_repo.authors).to be_empty
      core_repo.formulae.each { |formula| expect(formula.revisions).to be_empty }
    end
  end

  describe '#refresh' do
    it 'does nothing when nothing has changed' do
      core_repo.expects(:update_status).returns [[], [], 'deadbeef']
      Rails.logger.expects(:info).with 'No formulae changed.'
      core_repo.expects(:generate_history).never
      core_repo.stubs :save!

      core_repo.refresh
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

      def core_repo.fork
        yield
        1234
      end

      Process.expects(:wait).with 1234

      core_repo.expects(:require).with 'sandbox_backtick'
      core_repo.expects(:require).with 'sandbox_io_popen'
      Object.expects(:remove_const).with :Formula
      core_repo.expects(:require).with 'Library/Homebrew/global'
      core_repo.expects(:require).with 'Library/Homebrew/formula'
      core_repo.expects(:require).with 'Library/Homebrew/os/mac'
      core_repo.expects(:require).with 'sandbox_argv'
      core_repo.expects(:require).with 'sandbox_coretap'
      core_repo.expects(:require).with 'sandbox_development_tools'
      core_repo.expects(:require).with 'sandbox_formulary'
      core_repo.expects(:require).with 'sandbox_macos'
      core_repo.expects(:require).with 'sandbox_utils'
    end

    it 'sets some global information on the repo path' do
      main_repo.expects(:path).returns 'path'
      $LOAD_PATH.expects(:unshift).with File.join('path')
      $LOAD_PATH.expects(:unshift).with File.join('path', 'Library', 'Homebrew')

      core_repo.send :formulae_info, []

      expect($homebrew_path).to eq('path')
    end

    it 'uses a forked process to load formula information' do
      git = mock deps: [], desc: 'Distributed revision control system', homepage: 'http://git-scm.com', keg_only?: false, name: 'git', stable: mock(version: '1.7.9'), devel: nil, head: mock(version: 'HEAD')
      memcached = mock deps: %w(libevent), desc: 'High performance, distributed memory object caching system', homepage: 'http://memcached.org/', keg_only?: false, name: 'memcached', stable: mock(version: '1.4.11'), devel: mock(version: '2.0.0.dev') , head: nil

      Formula.expects(:class_s).with('git').returns :Git
      Formula.expects(:path).with('git').returns '/path/to/git'
      Formulary.expects(:factory).with('/path/to/git').returns git
      Formula.expects(:class_s).with('memcached').returns :Memcached
      Formula.expects(:path).with('memcached').returns '/path/to/memcached'
      Formulary.expects(:factory).with('/path/to/memcached').returns memcached

      formulae_info = core_repo.send :formulae_info, %w{git memcached}
      expect(formulae_info).to eq({
        'git' => { deps: [], description: 'Distributed revision control system', homepage: 'http://git-scm.com', keg_only: false, stable_version: '1.7.9', devel_version: nil, head_version:'HEAD' },
        'memcached' => { deps: %w(libevent), description: 'High performance, distributed memory object caching system', homepage: 'http://memcached.org/', keg_only: false, stable_version: '1.4.11', devel_version: '2.0.0.dev', head_version: nil }
      })
    end

    it 'reraises errors caused by the subprocess' do
      Formula.expects(:class_s).with('git').raises StandardError.new('subprocess failed')

      expect(-> { core_repo.send :formulae_info, %w{git} }).to raise_error(StandardError, 'subprocess failed')
    end

  end

  describe '#formula_regex' do

    let :repo do
      repo = Repository.new
      repo.extend subject
    end

    it 'returns a specific regex for the core repo' do
      expect(core_repo.formula_regex).to eq(/^(?:Library\/)?Formula\/(.+?)\.rb$/)
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
      core_repo.expects :clone_or_pull
      core_repo.expects(:git).with('log -1 --format=format:"%H %ct" HEAD').
        returns 'deadbeef 1325844635'
    end

    it 'can get the current status of a new full repository' do
      core_repo.expects(:git).with('ls-tree --name-only HEAD Formula/').
        returns "Formula/bazaar.rb\nFormula/git.rb\nFormula/mercurial.rb"
      core_repo.expects(:git).with('ls-tree --name-only HEAD Aliases/').
        returns "Aliases/bzr\nAliases/hg"

      formulae, aliases, last_sha = core_repo.update_status

      expect(formulae).to eq([%w{A Formula/bazaar.rb}, %w{A Formula/git.rb}, %w{A Formula/mercurial.rb}])
      expect(aliases).to eq([%w{A Aliases/bzr}, %w{A Aliases/hg}])
      expect(last_sha).to be_nil
    end

    it 'can get the current status of a new tap repository' do
      repo = core_repo
      repo.name = 'Homebrew/homebrew-science'
      repo.expects(:git).with('ls-tree --name-only -r HEAD').
        returns "bazaar.rb\ngit.rb\nmercurial.rb"

      formulae, aliases, last_sha = repo.update_status

      expect(formulae).to eq([%w{A bazaar.rb}, %w{A git.rb}, %w{A mercurial.rb}])
      expect(aliases).to eq([])
      expect(last_sha).to be_nil
    end

    it 'can update the current status of a repository' do
      core_repo.sha = '01234567'
      core_repo.expects(:git).with('diff --name-status 01234567..HEAD').
        returns "D\tAliases/bzr\nA\tAliases/hg\nD\tFormula/bazaar.rb\nM\tFormula/git.rb\nA\tFormula/mercurial.rb"
      Rails.logger.expects(:info).with "Updated #{Repository::CORE} from 01234567 to deadbeef:"

      formulae, aliases, last_sha = core_repo.update_status

      expect(formulae).to eq([%w{D Formula/bazaar.rb}, %w{M Formula/git.rb}, %w{A Formula/mercurial.rb}])
      expect(aliases).to eq([%w{D Aliases/bzr}, %w{A Aliases/hg}])
      expect(last_sha).to eq('01234567')
    end

    after do
      expect(core_repo.date).to eq(Time.at 1325844635)
      expect(core_repo.sha).to eq('deadbeef')
    end

  end

end
