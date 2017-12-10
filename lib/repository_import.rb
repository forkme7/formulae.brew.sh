# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014-2017, Sebastian Staudt

module RepositoryImport

  def clone_or_pull(reset = true)
    if File.exist? path
      Rails.logger.info "Pulling changes from #{name} into #{path}"
      git 'fetch --force --quiet origin master'
      if reset
        diff = git 'diff --shortstat HEAD FETCH_HEAD'
        unless diff.empty?
          git "--work-tree #{path} reset --hard --quiet FETCH_HEAD"
        end
      end
    else
      Rails.logger.info "Cloning #{name} into #{path}"
      git "clone --quiet #{url} #{path}"
    end
  end

  def git(command)
    command = "git --git-dir #{path}/.git #{command}"
    Rails.logger.debug "Executing `#{command}`"
    output = `#{command}`.strip

    raise "Execution of `#{command}` failed." unless $?.success?

    output
  end

  def main_repo
    Repository.main.extend RepositoryImport
  end

  def path
    "#{Braumeister::Application.tmp_path}/repos/#{name}"
  end

  def reset_head(sha = self.sha)
    git "--work-tree #{path} reset --hard --quiet #{sha}"
  end

  def update_status
    clone_or_pull

    last_sha = sha
    log = git('log -1 --format=format:"%H %ct" HEAD').split
    self.sha = log[0]
    self.date = Time.at log[1].to_i

    if last_sha.nil?
      Rails.logger.info "Checked out #{sha} in #{path}"
    elsif last_sha != sha
      Rails.logger.info "Updated #{name} from #{last_sha} to #{sha}:"
    end

    last_sha
  end

end
