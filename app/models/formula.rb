# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2014, Sebastian Staudt

class Formula

  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :_id, type: String, overwrite: true
  field :aliases, type: Array
  field :date, type: Time
  field :devel_version, type: String
  field :head_version, type: String
  field :keg_only, type: Boolean, default: false
  field :removed, type: Boolean, default: false
  field :name, type: String
  field :homepage, type: String
  field :path, type: String
  field :stable_version, type: String

  after_build :set_id

  alias_method :to_param, :name

  belongs_to :repository, validate: false
  has_and_belongs_to_many :revisions, inverse_of: nil, validate: false, index: true

  has_and_belongs_to_many :deps, class_name: self.to_s, inverse_of: :revdeps, validate: false, index: true
  has_and_belongs_to_many :revdeps, class_name: self.to_s, inverse_of: :deps, validate: false, index: true

  scope :letter, ->(letter) { where(name: /^#{letter.downcase}/) }

  def best_spec
    if stable_version
      :stable
    elsif devel_version
      :devel
    elsif head_version
      :head
    else
      nil
    end
  end

  def in_main?
    self.repository_id == Repository::MAIN
  end

  def path
    path = repository.full? ? File.join('Library', 'Formula') : self[:path]
    (path.nil? ? name : File.join(path, name)) + '.rb'
  end

  def raw_url
    "https://raw.github.com/#{repository.name}/HEAD/#{path}"
  end

  def generate_history!
    revisions.clear
    repository.generate_formula_history self
  end

  def update_metadata(formula_info)
    self.homepage = formula_info[:homepage]
    self.keg_only = formula_info[:keg_only]
    self.stable_version = formula_info[:stable_version]
    self.devel_version = formula_info[:devel_version]
    self.head_version = formula_info[:head_version]
  end

  def version
    stable_version || devel_version || head_version
  end

  private

  def set_id
    self._id = "#{repository.name}/#{name}"
  end

end
