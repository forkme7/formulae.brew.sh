# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

class Revision

  include Mongoid::Document

  field :_id, type: String, overwrite: true, default: ->{ sha }
  field :date, type: Time
  field :subject, type: String
  field :sha, type: String

  belongs_to :repository, validate: false
  belongs_to :author, validate: false

  has_and_belongs_to_many :added_formulae, class_name: 'Formula', inverse_of: nil, validate: false
  has_and_belongs_to_many :updated_formulae, class_name: 'Formula', inverse_of: nil, validate: false
  has_and_belongs_to_many :removed_formulae, class_name: 'Formula', inverse_of: nil, validate: false

  scope :without_bot, -> { where :author_id.nin => BOT_AUTHORS }

  BOT_AUTHORS = %w{
    brew-test-bot@googlegroups.com
    testbot@linuxbrew.sh
  }

end
