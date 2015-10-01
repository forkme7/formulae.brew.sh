# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2013, Sebastian Staudt

require File.expand_path('../boot', __FILE__)

require 'action_controller/railtie'
require 'sprockets/railtie'

Bundler.require :default, :assets, Rails.env

module Braumeister
  class Application < Rails::Application

    config.encoding = "utf-8"

    config.exceptions_app = ->(env) { ApplicationController.action(:error_page).call(env) }

    config.i18n.enforce_available_locales = false

    config.middleware.use Mongoid::QueryCache::Middleware

    Mongo::Logger.logger.level = Logger::WARN
    Mongoid.logger.level = Logger::WARN

    def self.tmp_path
      @@tmp_path ||= File.join Rails.root, 'tmp'
    end

  end
end
