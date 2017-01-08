# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2017, Sebastian Staudt

class Formulary

  class << self
    alias_method :original_factory, :factory
  end

  def self.core_path(name)
    formula = Repository.core.extend(TapImport).find_formula(name) || ''
    Pathname.new formula
  end

  def self.factory(ref)
    path = nil
    repo = @repositories.detect do |repo|
      repo.extend TapImport
      path = repo.find_formula ref
    end
    original_factory(path.nil? ? ref : File.join(repo.path, path))
  end

  class << self
    alias_method :get_formula, :factory
  end

  def self.repositories=(repositories)
    @repositories = repositories
  end

end
