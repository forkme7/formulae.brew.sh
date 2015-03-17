# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2014, Sebastian Staudt

require 'rails_helper'

describe FormulaeController do

  describe '#select_repository' do
    it 'sets the repository' do
      repo = mock
      repo.expects(:name).returns 'Homebrew/homebrew-versions'
      criteria = mock
      Repository.expects(:where).with(name: /^Homebrew\/homebrew-versions$/i).returns criteria
      criteria.expects(:only).with(:_id, :name, :sha, :updated_at).returns [ repo ]
      controller.expects(:params).returns({ repository_id: 'Homebrew/homebrew-versions' })

      controller.send :select_repository

      expect(controller.instance_variable_get(:@repository)).to eq(repo)
    end

    it 'redirects to the short url for Repository::MAIN' do
      request = mock
      request.expects(:url).twice.returns "http://braumeister.org/repos/#{Repository::MAIN}/browse"
      controller.expects(:request).twice.returns request
      controller.expects(:redirect_to).with '/browse'

      controller.send :select_repository
    end

    it 'the repository defaults to Repository::MAIN' do
      repo = mock
      repo.expects(:name).returns Repository::MAIN
      criteria = mock
      Repository.expects(:where).with(name: /^#{Repository::MAIN}$/i).returns criteria
      criteria.expects(:only).with(:_id, :name, :sha, :updated_at).returns [ repo ]

      controller.send :select_repository

      expect(controller.instance_variable_get(:@repository)).to eq(repo)
    end

    it 'redirects to the correct repository if capitalization is incorrect'

    it 'raises Mongoid::Errors::DocumentNotFound if no repository is found'
  end

  describe '#show' do
    context 'when formula is not found' do
      before do
        Formula.expects(:find).returns nil
        formulae = mock
        formulae.expects(:all_in).returns []
        repo = mock
        repo.expects(:formulae).returns formulae

        controller.stubs :select_repository
        controller.instance_variable_set :@repository, repo
        bypass_rescue
      end

      it 'should raise an error' do
        expect(-> { get :show, repository_id: 'Homebrew/homebrew-versions', id: 'git' }).
          to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

end
