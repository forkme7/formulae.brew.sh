# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2017, Sebastian Staudt

class Author

  include Mongoid::Document

  field :_id, type: String, overwrite: true, default: ->{ email }
  field :email, type: String
  field :name, type: String

  has_and_belongs_to_many :repositories, validate: false
  has_many :revisions, validate: false

end
