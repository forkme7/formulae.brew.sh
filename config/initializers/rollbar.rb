Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
  config.enabled = Rails.env.production?
  config.environment = ENV['ROLLBAR_ENV'] || Rails.env
  config.use_async = true

  config.exception_level_filters.merge!('ActionController::BadRequest' => 'ignore')
  config.exception_level_filters.merge!('ActionController::InvalidAuthenticityToken' => 'ignore')
  config.exception_level_filters.merge!('ActionController::InvalidCrossOriginRequest' => 'ignore')
end if defined? Rollbar
