# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013-2016, Sebastian Staudt

module Kernel

  ENCODING_HEADER = "# encoding: ascii\n"

  HOMEBREW_PREFIX = Repository.main.extend(RepositoryImport).path
  VERSION = RUBY_VERSION

  alias_method :orig_require, :require

  def require(name)
    begin
      orig_require name
    rescue LoadError
      # ignored
    rescue SyntaxError
      Rails.logger.debug "#{$!.message} in #{name}"
      candidate_files = $LOAD_PATH.map { |path| File.join(path, name) + '.rb' }
      file = candidate_files.find { |file| File.exist? file }
      begin
        eval ENCODING_HEADER + File.read(file), TOPLEVEL_BINDING
        $LOADED_FEATURES << file
      rescue Exception
        # ignored
      end
    end
  end

end
