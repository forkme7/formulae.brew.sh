# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

require 'repository_import'

if defined? ::NewRelic
  def task_with_tracing(*options)
    caller_method = options.first
    caller_method = caller_method.keys.first if caller_method.is_a? Hash

    task *options do
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

      perform_action_with_newrelic_trace name: caller_method.to_s, category: :task, force: true do
        yield
      end
    end
  end
else
  class << self
    alias_method :task_with_tracing, :task
  end
end

if defined? Airbrake
  def airbrake_rescued(&action)
    begin
      action.call
    rescue
      Airbrake.notify $!
    end
  end
else
  def airbrake_rescued(&action)
    action.call
  end
end

namespace :braumeister do

  Rails.logger = Logger.new STDOUT

  task :select_repos, [:repo] => :environment do |_, args|
    @repos = if args[:repo].nil?
      repos = ([Repository.core] + Repository.all).uniq
      repos.each { |repo| repo.extend RepositoryImport }
    else
      repo = Repository.unscoped.find args[:repo]
      repo.extend RepositoryImport
      [ repo ]
    end
  end

  desc 'Completely regenerates one or all repositories and their formulae'
  task_with_tracing :regenerate, [:repo] => :select_repos do
    @repos.each &:regenerate!
  end

  desc 'Regenerates the history of one or all repositories'
  task_with_tracing :regenerate_history, [:repo] => :select_repos do
    @repos.each &:generate_history!
  end

  desc 'Pulls the latest changes from one or all repositories'
  task_with_tracing :update, [:repo] => :select_repos do
    @repos.each do |repo|
      airbrake_rescued do
        last_sha = repo.refresh
        repo.generate_history last_sha
      end
    end
  end

end
