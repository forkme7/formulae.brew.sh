# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2017, Sebastian Staudt

require 'main_import'
require 'tap_import'

main = Repository.find_or_initialize_by name: Repository::MAIN
main.extend MainImport
main.update_status
main.create_missing_taps

core = Repository.find_or_initialize_by name: Repository::CORE
core.save!

([ core ] + Repository.all - [ main ]).uniq.each do |repo|
  repo.extend TapImport
  repo.refresh
  repo.generate_history
  repo.recover_deleted_formulae
  repo.save!
end
