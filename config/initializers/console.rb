# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

module Braumeister::Console

  def core
    @core ||= Repository.core.extend MainImport
  end

  def main
    @main ||= Repository.main.extend MainImport
  end

  def official_tap(name)
    Repository.find("Homebrew/homebrew-#{name}").extend TapImport
  end

end

Rails.application.console do
  require 'main_import'
  require 'tap_import'

  Rails::ConsoleMethods.include Braumeister::Console
end
