# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2017, Sebastian Staudt

class Formulary

  @@cache = {}

  def self.sandboxed_formula_from_contents(name, path, contents)
    formula = from_contents name, Pathname(path), contents
    formula.define_singleton_method(:caveats) { nil }
    @@cache[name] = formula
  end

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

    sandboxed_formula_from_contents ref, path, File.read(path)
  end

  def self.repositories=(repositories)
    @repositories = repositories.each { |r| r.extend TapImport }
  end

end
