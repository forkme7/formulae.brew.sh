if ENV.include? 'AIRBRAKE_API_KEY'
  Airbrake.configure do |config|
    config.api_key = ENV['AIRBRAKE_API_KEY']
    config.ignore << ActionController::BadRequest
  end
end
