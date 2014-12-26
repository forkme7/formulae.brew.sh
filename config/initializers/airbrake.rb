if ENV.include? 'AIRBRAKE_API_KEY'
  Airbrake.configure do |config|
    config.api_key = ENV['AIRBRAKE_API_KEY']
    config.ignore << ActionController::BadRequest
    config.ignore_by_filter do |notice|
      begin
        route = Rails.application.routes.recognize_path notice.url
        route[:action] == 'not_found' || route[:action] == 'forbidden'
      rescue ActionController::RoutingError
        true
      end
    end
  end
end
