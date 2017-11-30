# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'digest'

module FormulaeHelper

  def code_link(formula, revision)
    link_to 'Formula code', "https://github.com/#{formula.repository.name}/blob/#{revision.sha}/#{formula.path}", target: :_blank
  end

  def formula_diff_link(formula, rev)
    diff_md5 = Digest::MD5.hexdigest formula.path
    link_to '', "https://github.com/#{formula.repository.name}/commit/#{rev.sha}#diff-#{diff_md5}", target: :_blank
  end

  def feed_link
    feed_link = '/feed.atom'
    feed_link = "/repos/#{@repository.name}" + feed_link unless all?
    feed_link
  end

  def history_link(formula)
    link_to 'Complete formula history at GitHub', "https://github.com/#{formula.repository.name}/commits/HEAD/#{formula.path}", target: :_blank
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
