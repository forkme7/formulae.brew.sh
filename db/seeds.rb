# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

require 'repository_import'

Repository.include RepositoryImport

Repository.find_or_create_by name: 'Homebrew/brew'
Repository.find_or_create_by name: 'Homebrew/homebrew-core'
Repository.find_or_create_by name: 'Homebrew/homebrew-apache'
Repository.find_or_create_by name: 'Homebrew/homebrew-binary'
Repository.find_or_create_by name: 'Homebrew/homebrew-boneyard'
Repository.find_or_create_by name: 'Homebrew/homebrew-completions'
Repository.find_or_create_by name: 'Homebrew/homebrew-dupes'
Repository.find_or_create_by name: 'Homebrew/homebrew-games'
Repository.find_or_create_by name: 'Homebrew/homebrew-php'
Repository.find_or_create_by name: 'Homebrew/homebrew-python'
Repository.find_or_create_by name: 'Homebrew/homebrew-headonly'
Repository.find_or_create_by name: 'Homebrew/homebrew-science'
Repository.find_or_create_by name: 'Homebrew/homebrew-versions'

Repository.all.each do |repo|
  repo.refresh
  repo.recover_deleted_formulae
  repo.save!
end
