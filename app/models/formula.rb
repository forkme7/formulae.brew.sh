# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2017, Sebastian Staudt

class Formula

  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :_id, type: String, overwrite: true
  field :aliases, type: Array
  field :date, type: Time
  field :description, type: String
  field :devel_version, type: String
  field :head_version, type: String
  field :keg_only, type: Boolean, default: false
  field :removed, type: Boolean, default: false
  field :name, type: String
  field :homepage, type: String
  field :revision, type: Integer
  field :stable_version, type: String

  after_build :set_id

  alias_method :to_param, :name

  belongs_to :repository, validate: false
  has_and_belongs_to_many :revisions, inverse_of: nil, validate: false, index: true

  has_and_belongs_to_many :deps, class_name: self.to_s, inverse_of: :revdeps, validate: false, index: true
  has_and_belongs_to_many :optdeps, class_name: self.to_s, validate: false, index: true
  has_and_belongs_to_many :revdeps, class_name: self.to_s, inverse_of: :deps, validate: false, index: true

  scope :letter, ->(letter) { where(name: /^#{letter}/) }

  index( { repository_id: 1 }, { unique: false })
  index( { name: 1 }, { unique: false })

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

  def dupe?
    self.class.where(name: name).size > 1
  end

  def path
    (repository.formula_path.nil? ? name : File.join(repository.formula_path, name)) + '.rb'
  end

  def raw_url
    "https://raw.github.com/#{repository.name}/HEAD/#{path}"
  end

  def generate_history!
    revisions.clear
    repository.generate_formula_history self
  end

  def update_metadata(formula_info)
    self.description = formula_info['desc']
    self.homepage = formula_info['homepage']
    self.keg_only = formula_info['keg_only']
    self.stable_version = formula_info['versions']['stable']
    self.devel_version = formula_info['versions']['devel']
    self.head_version = formula_info['versions']['head']
    self.revision = formula_info['revision']

    self.deps = formula_info['build_dependencies'].map do |dep|
      repository.formulae.find_by(name: dep) || Repository.core.formulae.find_by(name: dep)
    end
    self.optdeps = formula_info['optional_dependencies'].map do |dep|
      repository.formulae.find_by(name: dep) || Repository.core.formulae.find_by(name: dep)
    end
  end

  def version
    stable_version || devel_version || head_version
  end

  def versions
    [ stable_version, devel_version, head_version ].compact
  end

  def set_id
    self._id = "#{repository.name}/#{name}"
  end

end
