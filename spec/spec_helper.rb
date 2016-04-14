# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2014, Sebastian Staudt

require 'rspec/rails'

RSpec.configure do |config|
  config.formatter = :documentation
  config.mock_with :mocha

  config.infer_base_class_for_anonymous_controllers = true
  config.infer_spec_type_from_file_location!

  config.before(:context) do
    Mongoid.default_client.collections.each &:drop

    Repository.create name: Repository::CORE, full: false
    Repository.create name: Repository::MAIN, full: true
  end
end
