# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2017, Sebastian Staudt

class Formulary

  @@cache = {}

  def self.factory(ref)
    return @@cache[ref] if @@cache.key? ref

    path = nil
    @repositories.each do |repo|
      formula = repo.find_formula(ref)
      unless formula.nil?
        path = File.join repo.path, formula
        break
      end
    end
    contents = File.read path
    @@cache[ref] = from_contents ref, Pathname(path), contents
  end

  def self.repositories=(repositories)
    @repositories = repositories.each { |r| r.extend TapImport }
  end

end
