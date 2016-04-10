# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

class Repository

  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  CORE = 'Homebrew/homebrew-core'
  MAIN = 'Homebrew/brew'

  field :_id, type: String, overwrite: true, default: ->{ name }
  field :date, type: Time
  field :full, type: Boolean, default: false
  field :name, type: String
  field :sha, type: String
  field :special_formula_regex, type: String

  has_and_belongs_to_many :authors, validate: false
  has_many :formulae, dependent: :destroy, validate: false
  has_many :revisions, dependent: :destroy, validate: false

  default_scope -> { where :name.ne => MAIN }

  def self.core
    find CORE
  end

  def self.main
    unscoped.find MAIN
  end

  def core?
    name == CORE
  end

  def feed_link
    feed_link = '/feed.atom'
    feed_link = "/repos/#{name}" + feed_link unless main?
    feed_link
  end

  def first_letter
    self.formulae.order_by(%i{name asc}).only(:name).limit(1).to_a.first.name[0]
  end

  def main?
    name == MAIN
  end

  def to_param
    name
  end

  def url
    "git://github.com/#{name}.git"
  end

end
