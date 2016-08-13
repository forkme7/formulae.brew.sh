source 'https://rubygems.org'
ruby '2.3.1'

gem 'compass-rails', '~> 2.0.0'
gem 'dalli', '~> 2.7.0'
gem 'font-awesome-sass', '~> 4.3'
gem 'jquery-cdn', '~> 2.2.4'
gem 'kaminari-mongoid', '~> 0.1.2'
gem 'mongoid', '~> 5.1.2'
gem 'rails', '4.2.7.1'
gem 'sass-rails', '~> 5.0'
gem 'text', '~> 1.3.0'
gem 'uglifier', '~> 2.7'
gem 'unicorn', '~> 4.8.1', platforms: :ruby

group :development do
  gem 'foreman', '~> 0.60'
end

group :development, :test do
  gem 'coveralls', '~> 0.8', require: false
  gem 'rspec-rails', '~> 3.2'
end

group :production do
  gem 'airbrake', '~> 5.2'
  gem 'newrelic_rpm', '~> 3.14'
  gem 'rails_12factor', '~> 0.0.2'
  gem 'skylight', '~> 0.10.0'
end

group :test do
  gem 'mocha', '~> 1.1.0', require: 'mocha/api'
end
