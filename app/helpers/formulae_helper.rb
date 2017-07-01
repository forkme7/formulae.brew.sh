# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'digest'

module FormulaeHelper

  def formula_diff_link(formula, rev)
    diff_md5 = Digest::MD5.hexdigest formula.path
    link_to '', "https://github.com/#{formula.repository.name}/commit/#{rev.sha}#diff-#{diff_md5}"
  end

  def feed_link
    feed_link = '/feed.atom'
    feed_link = "/repos/#{@repository.name}" + feed_link unless all?
    feed_link
  end

  def letters
    if all?
      Repository.all.map(&:letters).flatten.uniq.sort
    else
      @repository.letters
    end
  end

  def name
    all? ? nil : @repository.name
  end

  def repository_data
    { repository: @repository.name } unless all?
  end

end
