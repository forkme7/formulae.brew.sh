# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'rails_helper'

describe FormulaeHelper do

  describe '#code_link' do
    it 'returns a correct link to commit’s formula code' do
      formula = mock path: 'Formula/git.rb',
                     repository: mock(name: 'Homebrew/homebrew-core')
      revision = mock sha: 'deadbeef'

      expect(helper.code_link(formula, revision)).to eq('<a target="_blank" href="https://github.com/Homebrew/homebrew-core/blob/deadbeef/Formula/git.rb">Formula code</a>')
    end
  end

  describe '#feed_link' do
    it 'returns the short feed link for all repositories' do
      helper.stubs(:all?).returns true

      expect(helper.feed_link).to eq('/feed.atom')
    end

    it 'returns the full feed link for a specific repositiory' do
      helper.stubs(:all?).returns false
      helper.instance_variable_set :@repository, mock(name: 'Homebrew/homebrew-games')

      expect(helper.feed_link).to eq('/repos/Homebrew/homebrew-games/feed.atom')
    end
  end

  describe '#formula_diff_link' do
    it 'returns a correct link to the commit’s diff of the formula' do
      formula = mock path: 'Formula/git.rb',
                     repository: mock(name: 'Homebrew/homebrew-core')
      revision = mock sha: 'deadbeef'

      expect(helper.formula_diff_link(formula, revision)).to eq('<a target="_blank" href="https://github.com/Homebrew/homebrew-core/commit/deadbeef#diff-3e84bae646d908b93e043833873d316d"></a>')
    end
  end

  describe '#history_link' do
    it 'returns a correct link to the formula’s history on GitHub' do
      formula = mock path: 'Formula/git.rb',
                     repository: mock(name: 'Homebrew/homebrew-core')

      expect(helper.history_link(formula)).to eq('<a target="_blank" href="https://github.com/Homebrew/homebrew-core/commits/HEAD/Formula/git.rb">Complete formula history at GitHub</a>')
    end
  end

  describe '#letters' do
    let(:repo) do
      mock letters: %w[A B C]
    end

    it 'returns all available letters in all repositories' do
      helper.expects(:all?).returns true
      Repository.stubs(:all).returns [repo, mock(letters: %w[C D E F])]

      expect(helper.letters).to eq(%w[A B C D E F])
    end

    it 'returns all available letters in single repositories' do
      helper.expects(:all?).returns false
      helper.instance_variable_set :@repository, repo

      expect(helper.letters).to eq(%w[A B C])
    end
  end

  describe '#name' do
    it 'returns nil for all repositories' do
      helper.stubs(:all?).returns true

      expect(helper.name).to be_nil
    end

    it 'returns the name for a single repository' do
      helper.stubs(:all?).returns false
      helper.instance_variable_set :@repository, mock(name: 'Homebrew/homebrew-games')

      expect(helper.name).to eq('Homebrew/homebrew-games')
    end
  end

end
