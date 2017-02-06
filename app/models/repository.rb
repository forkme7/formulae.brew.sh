# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2017, Sebastian Staudt

class Repository

  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  CORE = 'Homebrew/homebrew-core'
  MAIN = 'Homebrew/brew'

  field :_id, type: String, overwrite: true, default: ->{ name }
  field :date, type: Time
  field :full, type: Boolean, default: false
  field :letters, type: Array, default: []
  field :name, type: String
  field :outdated, type: Boolean, default: true
  field :sha, type: String

  has_and_belongs_to_many :authors, validate: false
  has_many :formulae, dependent: :destroy, validate: false
  has_many :revisions, dependent: :destroy, validate: false

  default_scope -> { where :_id.ne => MAIN, :outdated => false }

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
    feed_link = "/repos/#{name}" + feed_link unless core?
    feed_link
  end

  def first_letter
    first_formula = formulae.order_by(%i{name asc}).only(:name).limit(1).to_a.first
    first_formula ? first_formula.name[0] : nil
  end

  def to_param
    name
  end

  def url
    "git://github.com/#{name}.git"
  end

end
