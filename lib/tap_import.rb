# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'repository_import'

module TapImport

  include RepositoryImport

  ALIAS_REGEX = /^(?:Library\/)?Aliases\/(.+?)$/

  def analyze_commits(log_params)
    reset_head
    log_cmd = "log --format=format:'%H%x00%ct%x00%aE%x00%aN%x00%s' --name-status --no-merges --find-copies=100% #{log_params}"

    commits = git(log_cmd).split /\n\n/
    commit_progress = 0
    commit_count = commits.size
    missing_formulae = []
    renames = {}
    until commits.empty? do
      commit_batch = commits.slice! 0, 100
      commit_batch.each do |commit|
        info, *files = commit.lines
        sha, timestamp, email, name, subject = info.strip.split "\x00"
        rev = Revision.find_or_initialize_by sha: sha
        self.revisions << rev
        rev.author = Author.find_or_initialize_by email: email
        self.authors << rev.author
        rev.author.name = name
        rev.author.save!
        rev.date = timestamp.to_i
        rev.subject = subject
        files.each do |file_status|
          status, name, new_name = file_status.split

          if status =~ /R\d\d\d/
            Rails.logger.info "Formula #{name} has been renamed to #{new_name} in repository."
            old_name = File.basename name, '.rb'
            name = renames[name] = renames[new_name] || File.basename(new_name, '.rb')
            next if missing_formulae.include? name
            formula = self.formulae.find_by name: name
            if formula.nil?
              Rails.logger.info "  Renaming formula #{old_name} to #{name}…"
              formula = self.formulae.find_by name: old_name
              unless formula.nil?
                formula.destroy!
                formula = formula.dup
                formula.name = name
                formula.set_id
                formula.save!
              end
            end
          else
            name = renames[name] || File.basename(name, '.rb')
            next if missing_formulae.include? name
            formula = self.formulae.find_by name: name
          end

          if formula.nil?
            Rails.logger.warn "Could not find a formula named #{name}."
            missing_formulae << name
            next
          end

          if status == 'A'
            rev.added_formulae << formula
          elsif status == 'D'
            rev.removed_formulae << formula
          else
            rev.updated_formulae << formula
          end

          formula.date = rev.date if formula.date.nil? || rev.date > formula.date
          formula.revisions << rev
          formula.save!
        end
        rev.save!
      end

      save!

      commit_progress += commit_batch.size
      Rails.logger.debug "Analyzed #{commit_progress} of #{commit_count} revisions."
    end
  end

  def clone_or_pull(reset = true)
    main_repo.clone_or_pull unless full?

    super
  end

  def repo
    Repository.core.extend RepositoryImport
  end

  def file_contents_for_sha(path, sha)
    return File.read path if sha.nil?

    git "cat-file blob #{sha}:#{path}"
  end

  def find_formula(file)
    file = file.to_s
    file.gsub! /(?<=[^\\])\+/, '\\\\+'
    file = file + '.rb' unless file.end_with? '.rb'
    git("ls-files | grep -E '(^|/)#{file}'").lines.first.strip rescue nil
  end

  def formulae_info(formulae, sha = nil)
    tmp_file = Tempfile.new 'braumeister-import'

    repositories = ([ Repository.core, self ] + Repository.all).uniq

    pid = fork do
      begin
        Object.send(:remove_const, :Formula) if Object.const_defined? :Formula

        $homebrew_path = main_repo.path
        $core_formula_path = repo.path
        $LOAD_PATH.unshift File.join($homebrew_path, 'Library', 'Homebrew')
        $LOADED_FEATURES.reject! { |path| path =~ /\/formula\.rb$/ }

        ENV['HOMEBREW_BREW_FILE'] = File.join $homebrew_path, 'bin', 'brew'
        ENV['HOMEBREW_CACHE'] = File.join $homebrew_path, 'Cache'
        ENV['HOMEBREW_CELLAR'] = File.join $homebrew_path, 'Cellar'
        ENV['HOMEBREW_LIBRARY'] = File.join $homebrew_path, 'Library'
        ENV['HOMEBREW_MACOS_VERSION'] = '10.12'
        ENV['HOMEBREW_PREFIX'] = $homebrew_path
        ENV['HOMEBREW_REPOSITORY'] = File.join $homebrew_path, '.git'

        require 'global'
        require 'formula'
        require 'os/mac'

        Homebrew.raise_deprecation_exceptions = false

        require 'sandbox/argv'
        require 'sandbox/coretap'
        require 'sandbox/formula'
        require 'sandbox/formulary'
        require 'sandbox/utils' unless sha.nil?

        Formulary.repositories = repositories

        formulae_info = {}
        formulae.each do |path|
          begin
            name = File.basename path, '.rb'
            contents = file_contents_for_sha path, sha

            formula = Formulary.from_contents name, Pathname(path), contents
            formulae_info[name] = formula.to_hash
          rescue FormulaSpecificationError, FormulaUnavailableError,
                 FormulaValidationError, NoMethodError, RuntimeError,
                 SyntaxError, TypeError
            error_msg = "Formula '#{name}' could not be imported because of an error:\n" <<
                    "    #{$!.class}: #{$!.message}"
            if $DEBUG
              $!.backtrace.each { |line| error_msg << "  #{line}\n" }
            end
            Rails.logger.warn error_msg
            if defined? Rollbar
              Rollbar.warning $!, error_msg, {
                formula: name,
                repository: self.name
              }
            end
          end
        end

        File.binwrite tmp_file, Marshal.dump(formulae_info)
      rescue
        File.binwrite tmp_file, Marshal.dump($!)
      end
    end

    Process.wait pid
    formulae_info = Marshal.load File.binread(tmp_file)
    tmp_file.unlink
    if formulae_info.is_a? StandardError
      raise formulae_info, formulae_info.message, formulae_info.backtrace
    end

    formulae_info
  end

  def formula_pathspec
    File.exists?(File.join path, 'Formula') ? 'Formula/*.rb' : '*.rb'
  end

  def generate_formula_history(formula)
    Rails.logger.info "Regenerating history for formula #{formula.name}..."

    analyze_commits "--follow -- #{formula.path}"
  end

  def generate_history!
    update_status

    Rails.logger.info "Resetting history of #{name}"
    self.formulae.each { |f| f.revisions.nullify }
    self.revisions.destroy
    self.revisions.clear
    self.authors.clear

    generate_history
  end

  def generate_history(last_sha = nil)
    return if last_sha == sha

    ref = last_sha.nil? ? 'HEAD' : "#{last_sha}..HEAD"

    Rails.logger.info "Regenerating history for #{ref}..."

    analyze_commits "#{ref} -- #{formula_pathspec}"
  end

  def recover_deleted_formulae
    clone_or_pull false
    reset_head

    log_cmd = "log --format=format:'%H' --diff-filter=D -M --name-only"
    log_cmd << " -- #{formula_pathspec}"

    git(log_cmd).split(/\n\n/).each do |commit|
      sha, *files = commit.lines
      sha.strip!

      files = files.map(&:strip)
      next if files.empty?

      Rails.logger.debug "Trying to recover the following formulae: #{files.join ', '}"
      begin
        sha << '^'

        Rails.logger.debug "Trying to import missing formulae from commit #{sha}…"

        formulae_info(files, sha).each_value do |formula_info|
          formula = self.formulae.find_or_initialize_by name: formula_info['name']
          next if formula_info.nil?
          formula.deps = formula_info['dependencies'].map do |dep|
            self.formulae.find_by(name: dep) ||
              Repository.core.formulae.find_by(name: dep)
          end
          formula.removed = true
          formula.update_metadata formula_info
          formula.save
          Rails.logger.info "Successfully recovered #{formula.name} from commit #{sha}"
        end
      rescue
        error_msg = "Commit #{sha} could not be imported because of an error: #{$!.message}"
        if $DEBUG
          $!.backtrace.each { |line| error_msg << "  #{line}\n" }
        end
        Rails.logger.debug error_msg
        retry unless sha =~ /\^\^\^\^\^/
      end
    end

    reset_head
  end

  def refresh
    formulae, aliases, last_sha = update_status

    if formulae.empty? && aliases.empty?
      Rails.logger.info 'No formulae changed.'
      touch
      save!
      return last_sha
    end

    formulae_info = formulae_info formulae.
            reject { |type, _| type == 'D' }.
            map { |_, path, new_path| File.join self.path, (new_path || path) }

    added = modified = removed = 0
    formulae.each do |type, fpath|
      path, name = File.split fpath
      name = File.basename name, '.rb'
      formula = self.formulae.find_or_initialize_by name: name
      formula.path = (core? || path == '.' ? nil : path)
      if type == 'D'
        removed += 1
        formula.removed = true
        Rails.logger.debug "Removed formula #{formula.name}."
      else
        if type == 'A'
          added += 1
          Rails.logger.debug "Added formula #{formula.name}."
        else
          modified += 1
          Rails.logger.debug "Updated formula #{formula.name}."
        end
        formula_info = formulae_info.delete formula.name
        next if formula_info.nil?
        formula.deps = formula_info['dependencies'].map do |dep|
          self.formulae.find_by(name: dep) ||
            Repository.core.formulae.find_by(name: dep)
        end
        formula.update_metadata formula_info
        formula.removed = false
      end
      formula.save!
    end

    aliases.each do |type, apath|
      name = apath.match(ALIAS_REGEX)[1]
      if type == 'D'
        formula = self.formulae.find_by aliases: name
        next if formula.nil?
        formula.aliases.delete name
      else
        alias_path = File.join path, apath
        next unless FileTest.symlink? alias_path
        formula_name  = File.basename File.readlink(alias_path), '.rb'
        formula = self.formulae.find_by name: formula_name
        next if formula.nil?
        formula.aliases ||= []
        formula.aliases << name
      end
      formula.save!
    end

    Rails.logger.info "#{added} formulae added, #{modified} formulae modified, #{removed} formulae removed."

    self.letters = ('a'..'z').select do |letter|
      self.formulae.letter(letter).where(removed: false).exists?
    end

    self.outdated = self.letters.empty?

    last_sha
  end

  def regenerate!
    FileUtils.rm_rf path
    Formula.delete_all repository_id: id
    Revision.delete_all repository_id: id

    Formula.each do |formula|
      formula.update_attribute :dep_ids, formula.dep_ids.reject! { |i| i.starts_with? "#{id}/" }
      formula.update_attribute :revdep_ids, formula.revdep_ids.reject! { |i| i.starts_with? "#{id}/" }
    end

    authors.clear
    formulae.clear
    revisions.clear
    self.sha = nil
    save!

    refresh
    recover_deleted_formulae
    generate_history
  end

  def update_metadata
    clone_or_pull false
    reset_head

    formulae = self.formulae.where(removed: false).
            map { |f| File.join path, f.path }.
            select { |p| File.exist? p }
    formulae_info(formulae).each do |name, formula_info|
      formula = self.formulae.find_by name: name
      formula.update_metadata formula_info
      formula.save!
    end
  end

  def update_status
    last_sha = super

    return [], [], sha if sha == last_sha

    if last_sha.nil?
      formulae = git "ls-files -- #{formula_pathspec}"
      formulae = formulae.lines.map { |file| ['A', file.strip] }

      if core?
        aliases = git 'ls-files -- Aliases/'
        aliases = aliases.lines.map { |file| ['A', file.strip] }
      else
        aliases = []
      end
    else
      formulae = git "diff --name-status #{last_sha}..HEAD -- #{formula_pathspec}"
      formulae = formulae.lines.map { |file| file.split }

      if core?
        aliases = git "diff --name-status #{last_sha}..HEAD -- Aliases/"
        aliases = aliases.lines.map { |file| file.split }
      else
        aliases = []
      end
    end

    unless core?
      formulae_path = File.join repo.path, 'Formula'
      Dir.glob File.join(path, '*.rb') do |formula|
        system('ln', '-s', formula, formulae_path, err: '/dev/null')
      end
    end

    return formulae, aliases, last_sha
  end

end
