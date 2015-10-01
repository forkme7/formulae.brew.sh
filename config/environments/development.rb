Braumeister::Application.configure do
  config.cache_classes = false
  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.active_support.deprecation = :log

  config.action_dispatch.best_standards_support = :builtin

  config.assets.compress = false
  config.assets.debug = true

  config.mongoid.preload_models = false

  Mongo::Logger.logger.level = Logger::INFO
  Mongoid.logger.level = Logger::INFO
end

$stdout.sync = true
