# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'rails_helper'

describe FormulaeHelper do

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

end
