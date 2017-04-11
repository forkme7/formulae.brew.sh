# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'repository_import'

module MainImport

  include RepositoryImport

  def create_missing_taps
    official_taps.each do |tap|
      tap_name = "Homebrew/homebrew-#{tap}"

      repo = Repository.find tap_name
      if repo.nil?
        Repository.create name: tap_name, outdated: false

        Rails.logger.info "Created tap repository for #{tap_name}."
      elsif repo.outdated?
        repo.outdated = false
        repo.save!
      end
    end
  end

  def official_taps
    official_taps_path = "#{path}/Library/Homebrew/official_taps.rb"
    official_taps_rb = File.read official_taps_path

    homebrew = Module.new
    homebrew.module_eval official_taps_rb, official_taps_path

    homebrew.const_get :OFFICIAL_TAPS
  end

  def update_status
    last_sha = super
    return last_sha if last_sha == sha
    save!

    last_sha
  end

end
